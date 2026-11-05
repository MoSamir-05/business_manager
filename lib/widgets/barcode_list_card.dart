
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/barcode_model.dart';
import '../core/utils/app_snackbar.dart';

class BarcodeListCard extends StatelessWidget {
  const BarcodeListCard({
    super.key,
    required this.barcode,
    this.onDelete,
  });

  final BarcodeModel barcode;
  final VoidCallback? onDelete;

  void _copyBarcode(BuildContext context) {
    Clipboard.setData(
      ClipboardData(text: barcode.barcodeNumber),
    );

    AppSnackBar.success(
      context,
      'Barcode number copied',
    );
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
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.qr_code_2_rounded,
                color: colorScheme.primary,
                size: 27,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    barcode.barcodeNumber,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scanned: ${barcode.scannedAt}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _copyBarcode(context),
              tooltip: 'Copy barcode number',
              icon: Icon(
                Icons.copy_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete barcode',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                  size: 21,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
