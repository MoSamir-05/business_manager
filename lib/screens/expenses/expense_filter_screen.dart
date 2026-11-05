import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ExpenseFilterScreen extends StatefulWidget {
  const ExpenseFilterScreen({
    super.key,
    this.initialCategory,
    this.initialStartDate,
    this.initialEndDate,
  });

  final String? initialCategory;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  @override
  State<ExpenseFilterScreen> createState() =>
      _ExpenseFilterScreenState();
}

class _ExpenseFilterScreenState extends State<ExpenseFilterScreen> {
  final List<String> _categories = const [
    'Food',
    'Travel',
    'Shopping',
    'Rent',
    'Bills',
    'Salary',
    'Maintenance',
    'Office Supplies',
    'Other',
  ];

  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    _selectedCategory = widget.initialCategory;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;

        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  void _applyFilter() {
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before start date.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      <String, dynamic>{
        'category': _selectedCategory,
        'startDate': _startDate,
        'endDate': _endDate,
      },
    );
  }

  void _resetFilter() {
    setState(() {
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Filter Expenses',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilter,
            child: const Text('Reset'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 9,
              runSpacing: 10,
              children: [
                _categoryChip('All', null),
                ..._categories.map(
                  (category) => _categoryChip(
                    category,
                    category,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            _dateTile(
              title: 'Start Date',
              date: _startDate,
              onTap: () => _selectDate(isStart: true),
            ),

            const SizedBox(height: 12),

            _dateTile(
              title: 'End Date',
              date: _endDate,
              onTap: () => _selectDate(isStart: false),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _applyFilter,
                icon: const Icon(Icons.filter_alt_rounded),
                label: const Text(
                  'Apply Filters',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, String? value) {
    final selected = _selectedCategory == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedCategory = value;
        });
      },
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    );
  }

  Widget _dateTile({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_rounded),
          ],
        ),
      ),
    );
  }
}