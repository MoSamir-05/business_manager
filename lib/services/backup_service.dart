
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Select a folder and create a backup.
  Future<String?> createBackup() async {
    final selectedDirectory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select Backup Folder',
    );

    if (selectedDirectory == null) {
      return null;
    }

    final directory = Directory(selectedDirectory);

    if (!await directory.exists()) {
      throw Exception('Selected backup folder does not exist.');
    }

    return _createBackupInDirectory(directory);
  }

  // Create backup inside selected directory.
  Future<String> _createBackupInDirectory(
    Directory directory,
  ) async {
    final db = await _databaseHelper.database;

    final employeePhotos = await db.query(
      'employees',
      columns: ['id', 'photo_path'],
    );

    final expenseReceipts = await db.query(
      'expenses',
      columns: ['id', 'receipt_path'],
    );

    final archive = Archive();
    final mediaManifest = <Map<String, String>>[];

    // Include employee photos.
    for (final employee in employeePhotos) {
      final photoPath = employee['photo_path'] as String?;

      if (photoPath == null || photoPath.isEmpty) {
        continue;
      }

      final file = File(photoPath);

      if (!await file.exists()) {
        continue;
      }

      final archiveName =
          'media/employee_${employee['id']}${p.extension(photoPath)}';

      final bytes = await file.readAsBytes();

      archive.addFile(
        ArchiveFile(archiveName, bytes.length, bytes),
      );

      mediaManifest.add({
        'type': 'employee',
        'id': employee['id'].toString(),
        'archive_path': archiveName,
      });
    }

    // Include expense receipt images.
    for (final expense in expenseReceipts) {
      final receiptPath = expense['receipt_path'] as String?;

      if (receiptPath == null || receiptPath.isEmpty) {
        continue;
      }

      final file = File(receiptPath);

      if (!await file.exists()) {
        continue;
      }

      final archiveName =
          'media/expense_${expense['id']}${p.extension(receiptPath)}';

      final bytes = await file.readAsBytes();

      archive.addFile(
        ArchiveFile(archiveName, bytes.length, bytes),
      );

      mediaManifest.add({
        'type': 'expense',
        'id': expense['id'].toString(),
        'archive_path': archiveName,
      });
    }

    final databasePath = await _databaseHelper.getDatabasePath();

    // Close database so pending SQLite changes are written.
    await _databaseHelper.closeDatabase();

    late final String backupPath;

    try {
      final databaseFile = File(databasePath);

      if (!await databaseFile.exists()) {
        throw Exception('Database file not found.');
      }

      final databaseBytes = await databaseFile.readAsBytes();

      archive.addFile(
        ArchiveFile(
          'database/business_manager.db',
          databaseBytes.length,
          databaseBytes,
        ),
      );

      final manifest = {
        'app_name': 'Business Manager',
        'backup_version': 1,
        'created_at': DateTime.now().toIso8601String(),
        'media': mediaManifest,
      };

      final manifestBytes = utf8.encode(jsonEncode(manifest));

      archive.addFile(
        ArchiveFile(
          'backup_manifest.json',
          manifestBytes.length,
          manifestBytes,
        ),
      );

      final zipBytes = ZipEncoder().encode(archive);

      if (zipBytes == null) {
        throw Exception('Could not create backup archive.');
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-');

      final backupFile = File(
        p.join(
          directory.path,
          'BusinessManager_$timestamp.bmbackup',
        ),
      );

      await backupFile.writeAsBytes(
        zipBytes,
        flush: true,
      );

      backupPath = backupFile.path;
    } finally {
      // Reopen database even if backup creation fails.
      await _databaseHelper.database;
    }

    // Save backup history.
    final reopenedDb = await _databaseHelper.database;

    final backupFile = File(backupPath);

    await reopenedDb.insert(
      'backup_history',
      {
        'file_path': backupPath,
        'file_size': await backupFile.length(),
        'backup_type': 'Manual',
        'backup_status': 'Success',
        'created_at': DateTime.now().toIso8601String(),
      },
    );

    return backupPath;
  }

  // Select an existing backup file (File Picker v13 API).
  Future<String?> selectBackupFile() async {
    final selectedFile = await FilePicker.pickFile(
      dialogTitle: 'Select Business Manager Backup',
      type: FileType.custom,
      allowedExtensions: ['bmbackup'],
    );

    if (selectedFile == null || selectedFile.path == null) {
      return null;
    }

    return selectedFile.path;
  }

  // Convert archive entry content into bytes.
  List<int> _getArchiveBytes(ArchiveFile file) {
    final content = file.content;

    if (content is List<int>) {
      return content;
    }

    throw const FormatException(
      'Backup file contains invalid data.',
    );
  }

  // Find an archive file by its exact path.
  ArchiveFile? _findArchiveFile(
    Archive archive,
    String archivePath,
  ) {
    for (final file in archive.files) {
      if (file.name == archivePath && file.isFile) {
        return file;
      }
    }

    return null;
  }

  // Restore backup after user confirmation.
  Future<void> restoreBackup(String backupPath) async {
    final backupFile = File(backupPath);

    if (!await backupFile.exists()) {
      throw Exception('Backup file does not exist.');
    }

    final backupBytes = await backupFile.readAsBytes();

    final Archive archive;

    try {
      archive = ZipDecoder().decodeBytes(backupBytes);
    } catch (_) {
      throw const FormatException(
        'Backup file is damaged or invalid.',
      );
    }

    ArchiveFile? databaseEntry;
    ArchiveFile? manifestEntry;

    for (final entry in archive.files) {
      if (entry.name == 'database/business_manager.db') {
        databaseEntry = entry;
      }

      if (entry.name == 'backup_manifest.json') {
        manifestEntry = entry;
      }
    }

    if (databaseEntry == null || manifestEntry == null) {
      throw const FormatException(
        'Invalid Business Manager backup file.',
      );
    }

    // Validate backup manifest.
    final manifestText = utf8.decode(
      _getArchiveBytes(manifestEntry),
    );

    final dynamic manifest;

    try {
      manifest = jsonDecode(manifestText);
    } catch (_) {
      throw const FormatException(
        'Backup manifest is invalid.',
      );
    }

    if (manifest is! Map ||
        manifest['app_name'] != 'Business Manager' ||
        manifest['backup_version'] != 1) {
      throw const FormatException(
        'Unsupported backup format.',
      );
    }

    final mediaList = manifest['media'];

    if (mediaList is! List) {
      throw const FormatException(
        'Backup media information is invalid.',
      );
    }

    final restoredDatabaseBytes =
        _getArchiveBytes(databaseEntry);

    // Prepare safety backup before replacing the database.
    final temporaryDirectory = await getTemporaryDirectory();

    final safetyFile = File(
      p.join(
        temporaryDirectory.path,
        'BusinessManager_PreRestore_'
        '${DateTime.now().millisecondsSinceEpoch}.db',
      ),
    );

    final currentDatabasePath =
        await _databaseHelper.getDatabasePath();

    final currentDatabaseFile = File(currentDatabasePath);

    await _databaseHelper.closeDatabase();

    try {
      if (!await currentDatabaseFile.exists()) {
        throw Exception('Current database file not found.');
      }

      // Copy existing database before restore.
      await currentDatabaseFile.copy(safetyFile.path);

      // Replace database with backup database.
      await currentDatabaseFile.writeAsBytes(
        restoredDatabaseBytes,
        flush: true,
      );

      final documentsDirectory =
          await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final employeeDirectory = Directory(
        p.join(
          documentsDirectory.path,
          'business_manager_media',
          'employees',
        ),
      );

      final receiptDirectory = Directory(
        p.join(
          documentsDirectory.path,
          'business_manager_media',
          'receipts',
        ),
      );

      await employeeDirectory.create(recursive: true);
      await receiptDirectory.create(recursive: true);

      final restoredMedia = <Map<String, dynamic>>[];

      // Restore media using unique filenames.
      // This avoids overwriting existing photos and receipts.
      for (final item in mediaList) {
        if (item is! Map) {
          continue;
        }

        final type = item['type'];
        final id = item['id'];
        final archivePath = item['archive_path'];

        if ((type != 'employee' && type != 'expense') ||
            id is! String ||
            archivePath is! String ||
            !archivePath.startsWith('media/')) {
          continue;
        }

        final mediaEntry = _findArchiveFile(
          archive,
          archivePath,
        );

        if (mediaEntry == null) {
          continue;
        }

        final extension = p.extension(archivePath);

        final destinationDirectory = type == 'employee'
            ? employeeDirectory
            : receiptDirectory;

        final prefix = type == 'employee'
            ? 'employee'
            : 'expense';

        final destination = File(
          p.join(
            destinationDirectory.path,
            '${prefix}_${id}_restore_$timestamp$extension',
          ),
        );

        await destination.writeAsBytes(
          _getArchiveBytes(mediaEntry),
          flush: true,
        );

        restoredMedia.add({
          'type': type,
          'id': int.parse(id),
          'path': destination.path,
        });
      }

      // Open restored database and update media paths.
      final restoredDb = await _databaseHelper.database;

      await restoredDb.transaction((txn) async {
        for (final media in restoredMedia) {
          final table = media['type'] == 'employee'
              ? 'employees'
              : 'expenses';

          final column = media['type'] == 'employee'
              ? 'photo_path'
              : 'receipt_path';

          await txn.update(
            table,
            {column: media['path']},
            where: 'id = ?',
            whereArgs: [media['id']],
          );
        }

        await txn.insert(
          'backup_history',
          {
            'file_path': backupFile.path,
            'file_size': await backupFile.length(),
            'backup_type': 'Restore',
            'backup_status': 'Success',
            'created_at': DateTime.now().toIso8601String(),
          },
        );
      });
    } catch (error) {
      // Restore original database if anything fails.
      await _databaseHelper.closeDatabase();

      if (await safetyFile.exists()) {
        await safetyFile.copy(currentDatabasePath);
      }

      rethrow;
    } finally {
      // Ensure database is open after success or failure.
      await _databaseHelper.database;
    }
  }

  // Get backup history.
  Future<List<Map<String, dynamic>>> getBackupHistory() async {
    final db = await _databaseHelper.database;

    return await db.query(
      'backup_history',
      orderBy: 'created_at DESC',
    );
  }

  // Get backup file size in readable format.
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
