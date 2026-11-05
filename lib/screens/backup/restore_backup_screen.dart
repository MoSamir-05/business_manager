
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backup_service.dart';

class RestoreBackupScreen extends StatefulWidget {
  const RestoreBackupScreen({super.key});

  @override
  State<RestoreBackupScreen> createState() =>
      _RestoreBackupScreenState();
}

class _RestoreBackupScreenState extends State<RestoreBackupScreen> {
  final BackupService _backupService = BackupService.instance;

  String? _selectedBackupPath;
  bool _isSelecting = false;
  bool _isRestoring = false;

  Future<void> _selectBackup() async {
    setState(() => _isSelecting = true);

    try {
      final path = await _backupService.selectBackupFile();

      if (!mounted) return;

      setState(() {
        _selectedBackupPath = path;
        _isSelecting = false;
      });

      if (path != null) {
        _showMessage('Backup file selected.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSelecting = false);
      _showMessage('Unable to select backup file.');
    }
  }

  Future<void> _restoreBackup() async {
    final path = _selectedBackupPath;

    if (path == null) {
      _showMessage('Please select a backup file first.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'Restoring this backup will replace the current '
          'business database with the selected backup.\n\n'
          'A safety backup should be created before restoration. '
          'Make sure you have selected the correct backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            child: const Text('Restore Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);

    try {
      await _backupService.restoreBackup(path);

      if (!mounted) return;

      setState(() {
        _isRestoring = false;
        _selectedBackupPath = null;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Restore Completed'),
          content: const Text(
            'Backup restoration completed successfully. '
            'Please close and reopen Business Manager '
            'to reload all restored data.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isRestoring = false);

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Restore Backup'),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Container(
                    height: 75,
                    width: 75,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      Icons.settings_backup_restore,
                      size: 38,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Restore Your Business Data',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Select a previously created Business Manager '
                    'backup file to restore your saved information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Selected Backup File',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    color: AppTheme.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedBackupPath == null
                          ? 'No backup file selected'
                          : _selectedBackupPath!.split('/').last,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _isSelecting || _isRestoring
                  ? null
                  : _selectBackup,
              icon: _isSelecting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.folder_open),
              label: Text(
                _isSelecting ? 'Selecting...' : 'Choose Backup File',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.warning.withOpacity(0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warning,
                    size: 25,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Important: Restoring a backup replaces your '
                      'current database. Newer data not included in '
                      'the selected backup may be lost. Keep a separate '
                      'copy of your latest backup.',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _selectedBackupPath == null ||
                        _isRestoring ||
                        _isSelecting
                    ? null
                    : _restoreBackup,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isRestoring
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.restore),
                label: Text(
                  _isRestoring ? 'Restoring...' : 'Restore Backup',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
