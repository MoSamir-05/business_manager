
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/utils/app_helpers.dart';
import '../widgets/status_badge.dart';

class BackupHistoryCard extends StatelessWidget {
  const BackupHistoryCard({
    super.key,
    required this.filePath,
    required this.fileSize,
    required this.backupType,
    required this.backupStatus,
    required this.createdAt,
    this.onTap,
    this.onDelete,
  });

  final String filePath;
  final int fileSize;
  final String backupType;
  final String backupStatus;
  final String createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  String _formatFileSize() {
    if (fileSize < 1024) {
      return '$fileSize B';
    }

    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    }

    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatCreatedAt() {
    final parsedDate = DateTime.tryParse(createdAt);

    if (parsedDate == null) {
      return createdAt;
    }

    return DateFormat('dd-MM-yyyy hh:mm a').format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.backup_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.cleanText(
                        filePath.split('/').last.split('\\').last,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${backupType.toUpperCase()} • ${_formatFileSize()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatCreatedAt(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StatusBadge(status: backupStatus),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete backup',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
