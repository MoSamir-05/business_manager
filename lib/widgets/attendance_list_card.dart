
import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../core/utils/app_date_utils.dart';
import 'status_badge.dart';

class AttendanceListCard extends StatelessWidget {
  const AttendanceListCard({
    super.key,
    required this.attendance,
    required this.employeeName,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final AttendanceModel attendance;
  final String employeeName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  String _formatAttendanceDate() {
    final parsedDate = AppDateUtils.parseDate(
      attendance.attendanceDate,
    );

    if (parsedDate == null) {
      return attendance.attendanceDate;
    }

    return AppDateUtils.formatDate(parsedDate);
  }

  IconData _getStatusIcon() {
    switch (attendance.status) {
      case AttendanceModel.present:
        return Icons.check_circle_outline_rounded;
      case AttendanceModel.absent:
        return Icons.cancel_outlined;
      case AttendanceModel.halfDay:
        return Icons.timelapse_rounded;
      case AttendanceModel.paidLeave:
        return Icons.event_available_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 12,
      ),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.45,
          ),
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
                  color: colorScheme.primary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: colorScheme.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatAttendanceDate(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (attendance.notes != null &&
                        attendance.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        attendance.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(status: attendance.status),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit?.call();
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
