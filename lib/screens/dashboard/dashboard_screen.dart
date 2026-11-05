
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService =
      DashboardService.instance;

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _recentExpenses = [];
  List<Map<String, dynamic>> _todayAttendance = [];
  List<Map<String, dynamic>> _monthlyChart = [];
  List<Map<String, dynamic>> _categoryChart = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _dashboardService.getDashboardSummary(),
        _dashboardService.getRecentExpenses(),
        _dashboardService.getTodayAttendance(),
        _dashboardService.getMonthlyExpenseChart(
          year: DateTime.now().year,
        ),
        _dashboardService.getExpenseCategoryChart(),
      ]);

      if (!mounted) return;

      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _recentExpenses =
            results[1] as List<Map<String, dynamic>>;
        _todayAttendance =
            results[2] as List<Map<String, dynamic>>;
        _monthlyChart =
            results[3] as List<Map<String, dynamic>>;
        _categoryChart =
            results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load dashboard data.';
      });
    }
  }

  double _number(String key) {
    return (_summary[key] as num?)?.toDouble() ?? 0;
  }

  int _count(String key) {
    return (_summary[key] as num?)?.toInt() ?? 0;
  }

  String _currency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '-';

    try {
      return DateFormat('dd MMM yyyy').format(
        DateTime.parse(value),
      );
    } catch (_) {
      return value;
    }
  }

  void _openRoute(String route) {
    Navigator.pushNamed(context, route).then((_) {
      if (mounted) _loadDashboard();
    });
  }

  Widget _sectionHeader(
    String title, {
    String? action,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                size: 17,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceSummaryCard() {
    final present = _count('present_today');
    final absent = _count('absent_today');
    final halfDay = _count('half_day_today');
    final paidLeave = _count('paid_leave_today');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Today's Attendance",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                DateFormat('dd MMM').format(DateTime.now()),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _attendanceValue('Present', present, AppTheme.success),
              _attendanceValue('Absent', absent, AppTheme.danger),
              _attendanceValue('Half Day', halfDay, AppTheme.warning),
              _attendanceValue('Leave', paidLeave, AppTheme.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attendanceValue(String title, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 9),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthlyExpenseChart() {
    final values = List<double>.filled(12, 0);

    for (final item in _monthlyChart) {
      final month = (item['month'] as num?)?.toInt() ?? 0;
      final total = (item['total'] as num?)?.toDouble() ?? 0;

      if (month >= 1 && month <= 12) {
        values[month - 1] = total;
      }
    }

    final maxValue = values.fold<double>(
      0,
      (previous, value) => value > previous ? value : previous,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Expenses',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Year ${DateTime.now().year}',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 155,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (index) {
                final value = values[index];

                final height = maxValue == 0
                    ? 4.0
                    : (value / maxValue * 105).clamp(4.0, 105.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (value > 0)
                          Tooltip(
                            message: _currency(value),
                            child: Text(
                              value >= 100000
                                  ? '${(value / 100000).toStringAsFixed(1)}L'
                                  : value >= 1000
                                      ? '${(value / 1000).toStringAsFixed(0)}K'
                                      : value.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 8,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                        const SizedBox(height: 5),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: height,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(
                              value == 0 ? 0.15 : 0.85,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          DateFormat('MMM').format(
                            DateTime(DateTime.now().year, index + 1),
                          ),
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryExpenseChart() {
    final total = _categoryChart.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['total'] as num?)?.toDouble() ?? 0),
    );

    final colors = [
      AppTheme.primary,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.info,
      AppTheme.danger,
      Colors.purple,
      Colors.teal,
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category-wise Expenses',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          if (_categoryChart.isEmpty || total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  'No expense data available.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ..._categoryChart.asMap().entries.map((entry) {
              final item = entry.value;
              final amount =
                  (item['total'] as num?)?.toDouble() ?? 0;
              final category =
                  item['category']?.toString() ?? 'Other';
              final color = colors[entry.key % colors.length];
              final percentage = (amount / total).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          _currency(amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8,
                        backgroundColor: AppTheme.border,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _recentExpenseCard(Map<String, dynamic> expense) {
    final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
    final title = expense['title']?.toString() ?? 'Expense';
    final category = expense['category']?.toString() ?? 'Other';
    final date = expense['expense_date']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$category • ${_formatDate(date)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _currency(amount),
            style: TextStyle(
              color: AppTheme.danger,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayAttendanceList() {
    if (_todayAttendance.isEmpty) {
      return _emptyMessage('No attendance marked today.');
    }

    return Column(
      children: _todayAttendance.take(5).map((item) {
        final name = item['employee_name']?.toString() ?? 'Employee';
        final status = item['status']?.toString() ?? '';
        final color = status == 'Present'
            ? AppTheme.success
            : status == 'Absent'
                ? AppTheme.danger
                : status == 'Half Day'
                    ? AppTheme.warning
                    : AppTheme.info;

        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Manager',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 45),
                      const SizedBox(height: 12),
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadDashboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(19),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3563E9),
                              Color(0xFF2449B8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Business Overview',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_count('total_employees')} Active Employees',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage your business from one place.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _sectionHeader('Business Summary'),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.30,
                        children: [
                          _summaryCard(
                            title: 'Employees',
                            value: _count('total_employees').toString(),
                            icon: Icons.people_alt_outlined,
                            color: AppTheme.primary,
                            subtitle: 'Active employees',
                          ),
                          _summaryCard(
                            title: 'Monthly Expenses',
                            value: _currency(_number('monthly_expenses')),
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppTheme.warning,
                            subtitle: 'Current month',
                          ),
                          _summaryCard(
                            title: 'Pending Salary',
                            value: _currency(_number('pending_salary')),
                            icon: Icons.payments_outlined,
                            color: AppTheme.danger,
                            subtitle: 'Remaining payment',
                          ),
                          _summaryCard(
                            title: 'Saved Barcodes',
                            value: _count('total_barcodes').toString(),
                            icon: Icons.qr_code_scanner,
                            color: AppTheme.info,
                            subtitle: 'Total saved numbers',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _attendanceSummaryCard(),

                      const SizedBox(height: 24),

                      _sectionHeader(
                        'Quick Actions',
                        action: 'View All',
                        onAction: () => _openRoute(AppRoutes.settings),
                      ),

                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 9,
                        mainAxisSpacing: 9,
                        childAspectRatio: 0.85,
                        children: [
                          _quickAction(
                            title: 'Expenses',
                            icon: Icons.receipt_long,
                            color: AppTheme.warning,
                            onTap: () => _openRoute(AppRoutes.expenses),
                          ),
                          _quickAction(
                            title: 'Employees',
                            icon: Icons.people,
                            color: AppTheme.primary,
                            onTap: () => _openRoute(AppRoutes.employees),
                          ),
                          _quickAction(
                            title: 'Attendance',
                            icon: Icons.fact_check,
                            color: AppTheme.success,
                            onTap: () => _openRoute(AppRoutes.attendance),
                          ),
                          _quickAction(
                            title: 'Salary',
                            icon: Icons.payments,
                            color: AppTheme.info,
                            onTap: () => _openRoute(AppRoutes.salary),
                          ),
                          _quickAction(
                            title: 'Barcode',
                            icon: Icons.qr_code_scanner,
                            color: AppTheme.primary,
                            onTap: () =>
                                _openRoute(AppRoutes.barcodeScanner),
                          ),
                          _quickAction(
                            title: 'Reports',
                            icon: Icons.analytics_outlined,
                            color: AppTheme.success,
                            onTap: () => _openRoute(AppRoutes.reports),
                          ),
                          _quickAction(
                            title: 'Backup',
                            icon: Icons.backup_outlined,
                            color: AppTheme.warning,
                            onTap: () => _openRoute(AppRoutes.backup),
                          ),
                          _quickAction(
                            title: 'Settings',
                            icon: Icons.settings_outlined,
                            color: AppTheme.textSecondary,
                            onTap: () => _openRoute(AppRoutes.settings),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _sectionHeader('Expense Analytics'),
                      _monthlyExpenseChart(),

                      const SizedBox(height: 16),

                      _categoryExpenseChart(),

                      const SizedBox(height: 24),

                      _sectionHeader(
                        'Recent Expenses',
                        action: 'See All',
                        onAction: () => _openRoute(AppRoutes.expenses),
                      ),

                      if (_recentExpenses.isEmpty)
                        _emptyMessage('No expenses added yet.')
                      else
                        ..._recentExpenses
                            .take(5)
                            .map(_recentExpenseCard),

                      const SizedBox(height: 18),

                      _sectionHeader(
                        "Today's Employee Attendance",
                        action: 'View All',
                        onAction: () =>
                            _openRoute(AppRoutes.attendanceHistory),
                      ),

                      _todayAttendanceList(),

                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          'Business Manager • Offline Business Solution',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
