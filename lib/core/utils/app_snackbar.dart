
import 'package:flutter/material.dart';

class AppSnackBar {
  AppSnackBar._();

  static void success(
    BuildContext context,
    String message,
  ) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xFF16A34A),
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void error(
    BuildContext context,
    String message,
  ) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xFFDC2626),
      icon: Icons.error_outline_rounded,
    );
  }

  static void warning(
    BuildContext context,
    String message,
  ) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xFFD97706),
      icon: Icons.warning_amber_rounded,
    );
  }

  static void info(
    BuildContext context,
    String message,
  ) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xFF2563EB),
      icon: Icons.info_outline_rounded,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }
}
