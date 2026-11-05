
import 'dart:io';

import 'package:flutter/material.dart';

import '../core/utils/app_helpers.dart';

class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({
    super.key,
    required this.name,
    this.photoPath,
    this.radius = 25,
    this.backgroundColor,
    this.textColor,
  });

  final String name;
  final String? photoPath;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final initials = AppHelpers.getInitials(name);

    final hasPhoto = photoPath != null &&
        photoPath!.trim().isNotEmpty;

    return Container(
      height: radius * 2,
      width: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ??
            colorScheme.primary.withValues(alpha: 0.12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.5,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.file(
              File(photoPath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildInitials(
                  initials,
                  colorScheme,
                );
              },
            )
          : _buildInitials(
              initials,
              colorScheme,
            ),
    );
  }

  Widget _buildInitials(
    String initials,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: textColor ?? colorScheme.primary,
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
