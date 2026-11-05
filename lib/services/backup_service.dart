
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

  static const String _appName = 'Business Manager';
  static const int _backupVersion = 1;

  // Select folder and create manual backup.
  Future<String?> createBackup() async {
    final selectedDirectory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select Backup Folder',
    );

    if (selectedDirectory == null) return null;

    final directory = Directory(selectedDirectory);

    if (!await directory.exists()) {
      throw Exception('Selected backup folder does not exist.');
    }

    return _createBackupInDirectory(
      directory,
      backupType: 'Manual',
    );
  }

  // Create backup archive.
  Future<String> _createBackupInDirectory(
    Directory directory, {
    required String backupType,
  }) async {
    final archive = Archive();
    final mediaManifest = <Map<String, String>>[];

    final db = await _databaseHelper.database;

    final employeePhotos = await db.query(
      'employees',
      columns: ['id', 'photo_path'],
    );

    final expenseReceipts = await db.query(
      'expenses',
      columns: ['id', 'receipt_path'],
    );

    // Add employee photos.
    for (final employee in employeePhotos) {
      final photoPath = employee['photo_path'] as String?;

      if (photoPath == null || photoPath.isEmpty) continue;

      final file = File(photoPath);

      if (!await file.exists()) continue;

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

    // Add expense receipt images.
    for (final expense in expenseReceipts) {
      final receiptPath = expense['receipt_path'] as String?;

      if (receiptPath == null || receiptPath.isEmpty) continue;

      final file = File(receiptPath);

      if (!await file.exists()) continue;

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

    await _databaseHelper.closeDatabase();

    String? backupPath;

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
        'app_name': _appName,
        'backup_version': _backupVersion,
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
        throw Exception('Unable to create backup archive.');
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
      await _databaseHelper.database;
    }

    if (backupPath == null) {
      throw Exception('Backup creation failed.');
    }

    // Save backup history.
    await _saveBackupHistory(
      backupPath,
      backupType: backupType,
      status: 'Success',
    );

    return backupPath;
  }

  Future<void> _saveBackupHistory(
    String filePath, {
    required String backupType,
    required String status,
  }) async {
    final db = await _databaseHelper.database;
    final file = File(filePath);

    final fileSize = await file.exists() ? await file.length() : 0;

    await db.insert(
      'backup_history',
      {
        'file_path': filePath,
        'file_size': fileSize,
        'backup_type': backupType,
        'backup_status': status,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // Select backup file.
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

  // Read archive bytes safely.
  List<int> _getArchiveBytes(ArchiveFile file) {
    final content = file.content;

    if (content is List<int>) {
      return content;
    }

    throw const FormatException(
      'Backup file contains invalid data.',
    );
  }

  // Find exact archive entry.
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

  // Validate backup without restoring it.
  Future<Map<String, dynamic>> validateBackup(
    String backupPath,
  ) async {
    final backupFile = File(backupPath);

    if (!await backupFile.exists()) {
      throw Exception('Backup file does not exist.');
    }

    final archive = _decodeArchive(
      await backupFile.readAsBytes(),
    );

    final databaseEntry = _findArchiveFile(
      archive,
      'database/business_manager.db',
    );

    final manifestEntry = _findArchiveFile(
      archive,
      'backup_manifest.json',
    );

    if (databaseEntry == null || manifestEntry == null) {
      throw const FormatException(
        'Invalid Business Manager backup file.',
      );
    }

    final manifest = _decodeManifest(
      _getArchiveBytes(manifestEntry),
    );

    final mediaList = manifest['media'];

    if (mediaList is! List) {
      throw const FormatException(
        'Backup media information is invalid.',
      );
    }

    // Check that every listed media file exists.
    int mediaCount = 0;

    for (final item in mediaList) {
      if (item is! Map) {
        throw const FormatException(
          'Invalid media entry in backup.',
        );
      }

      final type = item['type'];
      final id = item['id'];
      final archivePath = item['archive_path'];

      if ((type != 'employee' && type != 'expense') ||
          id is! String ||
          int.tryParse(id) == null ||
          archivePath is! String ||
          !archivePath.startsWith('media/') ||
          archivePath.contains('..')) {
        throw const FormatException(
          'Invalid media information in backup.',
        );
      }

      final mediaEntry = _findArchiveFile(
        archive,
        archivePath,
      );

      if (mediaEntry == null) {
        throw const FormatException(
          'A media file is missing from the backup.',
        );
      }

      mediaCount++;
    }

    return {
      'created_at': manifest['created_at'],
      'backup_version': manifest['backup_version'],
      'database_size': _getArchiveBytes(databaseEntry).length,
      'media_count': mediaCount,
      'file_size': await backupFile.length(),
    };
  }

  Archive _decodeArchive(List<int> bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException(
        'Backup file is damaged or invalid.',
      );
    }
  }

  Map<String, dynamic> _decodeManifest(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));

      if (decoded is! Map<String, dynamic> ||
          decoded['app_name'] != _appName ||
          decoded['backup_version'] != _backupVersion) {
        throw const FormatException(
          'Unsupported backup format.',
        );
      }

      return decoded;
    } catch (_) {
      throw const FormatException(
        'Backup manifest is invalid or unsupported.',
      );
    }
  }

  // Restore backup.
  Future<void> restoreBackup(String backupPath) async {
    final backupFile = File(backupPath);

    final preview = await validateBackup(backupPath);

    final backupBytes = await backupFile.readAsBytes();
    final archive = _decodeArchive(backupBytes);

    final databaseEntry = _findArchiveFile(
      archive,
      'database/business_manager.db',
    )!;

    final manifestEntry = _findArchiveFile(
      archive,
      'backup_manifest.json',
    )!;

    final manifest = _decodeManifest(
      _getArchiveBytes(manifestEntry),
    );

    final mediaList = manifest['media'] as List;

    final restoredDatabaseBytes =
        _getArchiveBytes(databaseEntry);

    // Save current database safety copy.
    final documentsDirectory =
        await getApplicationDocumentsDirectory();

    final safetyDirectory = Directory(
      p.join(
        documentsDirectory.path,
        'BusinessManagerSafetyBackups',
      ),
    );

    await safetyDirectory.create(recursive: true);

    final safetyFile = File(
      p.join(
        safetyDirectory.path,
        'PreRestore_${DateTime.now().millisecondsSinceEpoch}.db',
      ),
    );

    final currentDatabasePath =
        await _databaseHelper.getDatabasePath();

    final currentDatabaseFile = File(currentDatabasePath);

    // Close SQLite before replacing the database.
    await _databaseHelper.closeDatabase();

    final restoredMediaPaths = <Map<String, dynamic>>[];

    try {
      if (await currentDatabaseFile.exists()) {
        await currentDatabaseFile.copy(safetyFile.path);
      }

      // Replace database.
      await currentDatabaseFile.writeAsBytes(
        restoredDatabaseBytes,
        flush: true,
      );

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

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Restore photos and receipts.
      for (final item in mediaList) {
        final type = item['type'] as String;
        final id = int.parse(item['id'] as String);
        final archivePath = item['archive_path'] as String;

        final mediaEntry = _findArchiveFile(
          archive,
          archivePath,
        );

        if (mediaEntry == null) {
          throw const FormatException(
            'Backup media file is missing.',
          );
        }

        final destinationDirectory = type == 'employee'
            ? employeeDirectory
            : receiptDirectory;

        final prefix = type == 'employee'
            ? 'employee'
            : 'expense';

        final destination = File(
          p.join(
            destinationDirectory.path,
            '${prefix}_${id}_restore_$timestamp${p.extension(archivePath)}',
          ),
        );

        await destination.writeAsBytes(
          _getArchiveBytes(mediaEntry),
          flush: true,
        );

        restoredMediaPaths.add({
          'type': type,
          'id': id,
          'path': destination.path,
        });
      }

      final restoredDb = await _databaseHelper.database;

      // Update database paths for restored media.
      await restoredDb.transaction((txn) async {
        for (final media in restoredMediaPaths) {
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
            'file_size': preview['file_size'],
            'backup_type': 'Restore',
            'backup_status': 'Success',
            'created_at': DateTime.now().toIso8601String(),
          },
        );
      });
    } catch (error) {
      // Restore previous database if restore fails.
      await _databaseHelper.closeDatabase();

      if (await safetyFile.exists()) {
        await safetyFile.copy(currentDatabasePath);
      }

      rethrow;
    } finally {
      await _databaseHelper.database;
    }
  }

  // Backup history.
  Future<List<Map<String, dynamic>>> getBackupHistory() async {
    final db = await _databaseHelper.database;

    return await db.query(
      'backup_history',
      orderBy: 'created_at DESC',
    );
  }

  // File size formatting.
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
