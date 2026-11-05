
import 'package:flutter/material.dart';

import '../models/salary_payment_model.dart';
import 'currency_text.dart';

class SalaryPaymentCard extends StatelessWidget {
  const SalaryPaymentCard({
    super.key,
    required this.payment,
    this.onTap,
  });

  final SalaryPaymentModel payment;
  final VoidCallback? onTap;

  IconData _getPaymentIcon() {
    switch (payment.paymentMethod.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'upi':
        return Icons.qr_code_rounded;
      case 'bank':
        return Icons.account_balance_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
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
                  _getPaymentIcon(),
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
                      payment.paymentMethod,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      payment.paymentDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (payment.note != null &&
                        payment.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        payment.note!,
                        maxLines: 2,
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
              CurrencyText(
                amount: payment.amount,
                fontSize: 16,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
