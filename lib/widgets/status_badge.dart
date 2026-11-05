
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  final String status;
  final double fontSize;

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
      case 'present':
      case 'paid':
      case 'success':
        return const Color(0xFF16A34A);

      case 'inactive':
      case 'absent':
      case 'pending':
      case 'unpaid':
      case 'failed':
        return const Color(0xFFDC2626);

      case 'half day':
      case 'partial':
      case 'warning':
        return const Color(0xFFD97706);

      case 'paid leave':
      case 'info':
        return const Color(0xFF2563EB);

      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
