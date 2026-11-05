
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatelessWidget {
  const CustomDatePicker({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.hint,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? hint;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  Future<void> _selectDate(BuildContext context) async {
    if (!enabled) return;

    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      helpText: 'Select $label',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FormField<DateTime>(
      initialValue: selectedDate,
      validator: validator,
      builder: (field) {
        final date = selectedDate ?? field.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: enabled
                  ? () async {
                      await _selectDate(context);
                      field.didChange(selectedDate);
                    }
                  : null,
              borderRadius: BorderRadius.circular(15),
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: hint ?? 'Select $label',
                  prefixIcon: const Icon(
                    Icons.calendar_month_outlined,
                  ),
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  errorText: field.errorText,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Text(
                  date != null
                      ? DateFormat('dd-MM-yyyy').format(date)
                      : hint ?? 'Select $label',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: date != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
