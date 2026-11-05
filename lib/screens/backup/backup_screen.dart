
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService.instance;

  List<Map<String, dynamic>> _history = [];

  bool _isLoading = true;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final result = await _backupService.getBackupHistory();

      if (!mounted) return;

      setState(() {
        _history = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Backup history load nahi hui: $e');
    }
  }

  Future<void> _createBackup() async {
    if (_isBackingUp || _isRestoring) return;

    setState(() => _isBackingUp = true);

    try {
      final path = await _backupService.createBackup();

      if (!mounted) return;

      if (path == null) {
        _showMessage('Backup folder select nahi kiya gaya.');
      } else {
        _showMessage(
          'Backup successfully created!\n$path',
          color: AppTheme.success,
          duration: 6,
        );

        await _loadHistory();
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Backup create nahi hua: $e',
        color: AppTheme.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _restoreBackup() async {
    if (_isBackingUp || _isRestoring) return;

    final selectedPath = await _backupService.selectBackupFile();

    if (!mounted || selectedPath == null) return;

    final file = File(selectedPath);

    if (!await file.exists()) {
      _showMessage('Selected backup file nahi mili.');
      return;
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warning,
            size: 38,
          ),
          title: const Text('Restore Backup?'),
          content: const Text(
            'Restore karne se current database replace ho jayega. '
            'Backup mein available purana data restore hoga. '
            'Current database ki safety copy banane ki koshish ki jayegi.\n\n'
            'Kya aap continue karna chahte hain?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.danger,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => _isRestoring = true);

    try {
      await _backupService.restoreBackup(selectedPath);

      if (!mounted) return;

      _showMessage(
        'Backup successfully restored. App ko restart karke data refresh karein.',
        color: AppTheme.success,
        duration: 6,
      );

      await _loadHistory();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Restore failed: $e',
        color: AppTheme.danger,
        duration: 6,
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(
        DateTime.parse(value.toString()),
      );
    } catch (_) {
      return value.toString();
    }
  }

  void _showMessage(
    String message, {
    Color? color,
    int duration = 3,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: Duration(seconds: duration),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String buttonText,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              description,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon, size: 19),
                label: Text(
                  isLoading ? 'Please wait...' : buttonText,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final path = item['file_path']?.toString() ?? '';
    final type = item['backup_type']?.toString() ?? 'Backup';
    final status = item['backup_status']?.toString() ?? 'Unknown';

    final fileSize = item['file_size'] is num
        ? (item['file_size'] as num).toInt()
        : 0;

    final isSuccess = status.toLowerCase() == 'success';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.10),
              child: Icon(
                type.toLowerCase() == 'restore'
                    ? Icons.restore
                    : Icons.backup_outlined,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatDate(item['created_at']),
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _backupService.formatFileSize(fileSize),
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (path.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: (isSuccess
                        ? AppTheme.success
                        : AppTheme.danger)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: isSuccess
                      ? AppTheme.success
                      : AppTheme.danger,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 35),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.backup_outlined,
                size: 50,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No backup history available',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Create your first backup to see it here.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _history.map(_buildHistoryCard).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isBackingUp || _isRestoring;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            onPressed: isBusy ? null : _loadHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh history',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppTheme.primary,
                      size: 25,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Protect Your Business Data',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Database, employee photos aur expense receipts '
                            'ka backup external folder mein save karein.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              _buildActionCard(
                title: 'Create Backup',
                description:
                    'Apna complete business data selected folder mein '
                    'Business Manager backup file ke roop mein save karein.',
                icon: Icons.backup_outlined,
                color: AppTheme.primary,
                buttonText: 'Create New Backup',
                onPressed: isBusy ? null : _createBackup,
                isLoading: _isBackingUp,
              ),

              _buildActionCard(
                title: 'Restore Backup',
                description:
                    'Pehle se saved .bmbackup file select karke '
                    'business data restore karein.',
                icon: Icons.restore,
                color: AppTheme.warning,
                buttonText: 'Select Backup File',
                onPressed: isBusy ? null : _restoreBackup,
                isLoading: _isRestoring,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Backup History',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${_history.length} records',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _buildHistory(),
            ],
          ),
        ),
      ),
    );
  }
}
