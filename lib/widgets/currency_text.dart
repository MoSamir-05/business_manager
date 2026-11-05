
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyText extends StatelessWidget {
  const CurrencyText({
    super.key,
    required this.amount,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.showDecimals = false,
    this.maxLines = 1,
  });

  final double amount;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final bool showDecimals;
  final int maxLines;

  String get formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: showDecimals ? 2 : 0,
    );

    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      formattedAmount,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? theme.colorScheme.onSurface,
      ),
    );
  }
}
