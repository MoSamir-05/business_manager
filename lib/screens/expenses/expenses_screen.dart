import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../widgets/expense_list_card.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpenseService _expenseService = ExpenseService.instance;
  final TextEditingController _searchController =
      TextEditingController();

  late Future<List<ExpenseModel>> _expensesFuture;

  double _totalExpenses = 0;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    setState(() {
      _expensesFuture = _expenseService.getAllExpenses();
    });

    _loadTotal();
  }

  Future<void> _loadTotal() async {
    final total = await _expenseService.getTotalExpenses();

    if (!mounted) return;

    setState(() {
      _totalExpenses = total;
    });
  }

  Future<void> _searchExpenses(String query) async {
    setState(() {
      _isSearching = query.trim().isNotEmpty;

      _expensesFuture = _isSearching
          ? _expenseService.searchExpenses(query.trim())
          : _expenseService.getAllExpenses();
    });
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    if (expense.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense?'),
          content: Text(
            'Are you sure you want to delete "${expense.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.danger,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _expenseService.deleteExpense(expense.id!);

    if (!mounted) return;

    _loadExpenses();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense deleted successfully'),
      ),
    );
  }

  void _openAddExpense() {
    Navigator.pushNamed(
      context,
      AppRoutes.addExpense,
    ).then((_) {
      if (mounted) {
        _loadExpenses();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Expenses',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadExpenses,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTotalCard(isDark),
            _buildSearchField(theme),
            Expanded(
              child: FutureBuilder<List<ExpenseModel>>(
                future: _expensesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildMessage(
                      icon: Icons.error_outline_rounded,
                      title: 'Something went wrong',
                      subtitle: 'Please refresh and try again.',
                      action: 'Retry',
                      onAction: _loadExpenses,
                    );
                  }

                  final expenses = snapshot.data ?? [];

                  if (expenses.isEmpty) {
                    return _buildMessage(
                      icon: Icons.receipt_long_outlined,
                      title: _isSearching
                          ? 'No expenses found'
                          : 'No expenses yet',
                      subtitle: _isSearching
                          ? 'Try searching with another keyword.'
                          : 'Your added expenses will appear here.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadExpenses();
                      await _expensesFuture;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        100,
                      ),
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final expense = expenses[index];

                        return ExpenseListCard(
                          expense: expense,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.expenseDetails,
                              arguments: expense,
                            ).then((_) {
                              if (mounted) {
                                _loadExpenses();
                              }
                            });
                          },
                          onEdit: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.addExpense,
                              arguments: expense,
                            ).then((_) {
                              if (mounted) {
                                _loadExpenses();
                              }
                            });
                          },
                          onDelete: () {
                            _deleteExpense(expense);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Total Expenses',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${_totalExpenses.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'All recorded expenses',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: _searchExpenses,
        decoration: InputDecoration(
          hintText: 'Search expenses...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchExpenses('');
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: true,
          fillColor: theme.cardColor,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: AppTheme.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: AppTheme.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: AppTheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    String? action,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 58,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                child: Text(action),
              ),
            ],
          ],
        ),
      ),
    );
  }
}