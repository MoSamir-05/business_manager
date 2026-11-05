
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    this.expense,
  });

  final ExpenseModel? expense;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ExpenseService _expenseService = ExpenseService.instance;

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

  final List<String> _paymentMethods = const [
    'Cash',
    'UPI',
    'Bank',
  ];

  String? _selectedCategory;
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();

    final expense = widget.expense;

    if (expense != null) {
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toString();
      _descriptionController.text = expense.description;

      _selectedCategory = expense.category;
      _selectedPaymentMethod = expense.paymentMethod;

      _selectedDate = _parseExpenseDate(expense.expenseDate);
    }
  }

  DateTime _parseExpenseDate(String value) {
    // First try ISO format: yyyy-MM-dd
    final isoDate = DateTime.tryParse(value);

    if (isoDate != null) {
      return isoDate;
    }

    // Handle dd-MM-yyyy format
    final parts = value.split('-');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        if (month >= 1 && month <= 12 &&
            day >= 1 && day <= 31) {
          final parsedDate = DateTime(year, month, day);

          if (parsedDate.day == day &&
              parsedDate.month == month &&
              parsedDate.year == year) {
            return parsedDate;
          }
        }
      }
    }

    // Handle dd/MM/yyyy format
    final slashParts = value.split('/');

    if (slashParts.length == 3) {
      final day = int.tryParse(slashParts[0]);
      final month = int.tryParse(slashParts[1]);
      final year = int.tryParse(slashParts[2]);

      if (day != null && month != null && year != null) {
        final parsedDate = DateTime(year, month, day);

        if (parsedDate.day == day &&
            parsedDate.month == month &&
            parsedDate.year == year) {
          return parsedDate;
        }
      }
    }

    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      _showMessage('Please select an expense category.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now().toIso8601String();

      final expense = ExpenseModel(
        id: widget.expense?.id,
        title: _titleController.text.trim(),
        category: _selectedCategory!,
        amount: amount,
        description: _descriptionController.text.trim(),
        expenseDate: _formatDate(_selectedDate),
        paymentMethod: _selectedPaymentMethod,
        receiptPath: widget.expense?.receiptPath,
        createdAt: widget.expense?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await _expenseService.updateExpense(expense);
      } else {
        await _expenseService.addExpense(expense);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Expense updated successfully.'
                : 'Expense added successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Unable to save expense. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _buildSectionTitle('Expense Information'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _titleController,
                label: 'Expense Title',
                hint: 'e.g. Electricity Bill',
                prefixIcon: Icons.receipt_long_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter expense title.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              CustomTextField(
                controller: _amountController,
                label: 'Amount',
                hint: 'Enter amount',
                prefixIcon: Icons.currency_rupee_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount.';
                  }

                  final amount = double.tryParse(value.trim());

                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              CustomDropdown<String>(
                label: 'Category',
                hint: 'Select category',
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              _buildSectionTitle('Payment Details'),
              const SizedBox(height: 16),

              CustomDropdown<String>(
                label: 'Payment Method',
                hint: 'Select payment method',
                value: _selectedPaymentMethod,
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 18),

              _buildDatePicker(),

              const SizedBox(height: 18),

              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'Add expense details...',
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
              ),

              const SizedBox(height: 28),

              PrimaryButton(
                text: _isEditing ? 'Update Expense' : 'Save Expense',
                icon: Icons.save_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveExpense,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(15),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Expense Date',
          prefixIcon: Icon(Icons.calendar_month_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.edit_calendar_rounded,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
