import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
// import '../../widgets/currency_text.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  const ExpenseDetailsScreen({
    super.key,
    required this.expense,
  });

  final ExpenseModel expense;

  @override
  State<ExpenseDetailsScreen> createState() =>
      _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  final ExpenseService _expenseService = ExpenseService.instance;

  late ExpenseModel _expense;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text(
          'Are you sure you want to delete this expense?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || _expense.id == null) return;

    try {
      await _expenseService.deleteExpense(_expense.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted successfully.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete expense.'),
        ),
      );
    }
  }

  void _editExpense() {
    Navigator.pop(context, _expense);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Expense Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _deleteExpense,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.danger,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildAmountCard(),
          const SizedBox(height: 22),

          const Text(
            'Expense Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          _buildDetailRow(
            icon: Icons.receipt_long_outlined,
            title: 'Expense Title',
            value: _expense.title,
          ),
          _buildDetailRow(
            icon: Icons.category_outlined,
            title: 'Category',
            value: _expense.category,
          ),
          _buildDetailRow(
            icon: Icons.calendar_month_outlined,
            title: 'Expense Date',
            value: _expense.expenseDate,
          ),
          _buildDetailRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payment Method',
            value: _expense.paymentMethod,
          ),
          _buildDetailRow(
            icon: Icons.notes_rounded,
            title: 'Description',
            value: _expense.description.isEmpty
                ? 'No description added'
                : _expense.description,
          ),

          if (_expense.receiptPath != null &&
              _expense.receiptPath!.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'Receipt Photo',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildReceipt(),
          ],

          const SizedBox(height: 28),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _editExpense,
              icon: const Icon(Icons.edit_rounded),
              label: const Text(
                'Edit Expense',
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

          const SizedBox(height: 12),

          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _deleteExpense,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.danger,
              ),
              label: const Text(
                'Delete Expense',
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white70,
            size: 30,
          ),
          const SizedBox(height: 12),
          const Text(
            'Expense Amount',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_expense.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primary,
            size: 21,
          ),
          const SizedBox(width: 13),
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
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceipt() {
    final file = File(_expense.receiptPath!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        file,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Receipt image not available'),
          );
        },
      ),
    );
  }
}