
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/employee_model.dart';
import '../../models/salary_model.dart';
import '../../services/employee_service.dart';
import '../../services/salary_service.dart';

class SalaryHistoryScreen extends StatefulWidget {
  const SalaryHistoryScreen({super.key});

  @override
  State<SalaryHistoryScreen> createState() =>
      _SalaryHistoryScreenState();
}

class _SalaryHistoryScreenState extends State<SalaryHistoryScreen> {
  final EmployeeService _employeeService = EmployeeService.instance;
  final SalaryService _salaryService = SalaryService.instance;

  List<EmployeeModel> _employees = [];
  List<SalaryModel> _salaryRecords = [];

  EmployeeModel? _selectedEmployee;

  bool _isLoadingEmployees = true;
  bool _isLoadingHistory = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _employeeService.getAllEmployees();

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingEmployees = false);
      _showMessage('Employees load nahi hue: $e');
    }
  }

  Future<void> _loadSalaryHistory(int employeeId) async {
    setState(() {
      _isLoadingHistory = true;
      _salaryRecords = [];
    });

    try {
      final records =
          await _salaryService.getEmployeeSalaryHistory(employeeId);

      if (!mounted) return;

      records.sort((a, b) {
        final aDate = DateTime(a.salaryYear, a.salaryMonth);
        final bDate = DateTime(b.salaryYear, b.salaryMonth);
        return bDate.compareTo(aDate);
      });

      setState(() {
        _salaryRecords = records;
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingHistory = false);
      _showMessage('Salary history load nahi hui: $e');
    }
  }

  void _onEmployeeSelected(EmployeeModel? employee) {
    if (employee == null) return;

    setState(() {
      _selectedEmployee = employee;
    });

    if (employee.id != null) {
      _loadSalaryHistory(employee.id!);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  String _monthName(int month, int year) {
    return DateFormat('MMMM yyyy').format(DateTime(year, month));
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppTheme.success;
      case 'partial':
        return AppTheme.warning;
      default:
        return AppTheme.danger;
    }
  }

  Widget _buildEmployeeSelector() {
    if (_isLoadingEmployees) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_employees.isEmpty) {
      return const Text('Abhi koi employee available nahi hai.');
    }

    return DropdownButtonFormField<EmployeeModel>(
      initialValue: _selectedEmployee,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Select Employee',
        prefixIcon: const Icon(Icons.person_outline),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      items: _employees.map((employee) {
        return DropdownMenuItem<EmployeeModel>(
          value: employee,
          child: Text(
            employee.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onEmployeeSelected,
    );
  }

  Widget _buildSummary() {
    final totalSalary = _salaryRecords.fold<double>(
      0,
      (sum, record) => sum + record.finalPayable,
    );

    final totalPaid = _salaryRecords.fold<double>(
      0,
      (sum, record) => sum + record.paidAmount,
    );

    final totalPending = _salaryRecords.fold<double>(
      0,
      (sum, record) => sum + record.remainingAmount,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Total Salary',
                amount: totalSalary,
                icon: Icons.account_balance_wallet_outlined,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: 'Total Paid',
                amount: totalPaid,
                icon: Icons.check_circle_outline,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _summaryCard(
          title: 'Total Pending',
          amount: totalPending,
          icon: Icons.pending_actions,
          color: AppTheme.warning,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryCard(SalaryModel record) {
    final statusColor = _statusColor(record.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _monthName(
                      record.salaryMonth,
                      record.salaryYear,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _detailRow(
              'Final Salary',
              _formatCurrency(record.finalPayable),
            ),
            _detailRow(
              'Paid Amount',
              _formatCurrency(record.paidAmount),
            ),
            _detailRow(
              'Pending Amount',
              _formatCurrency(record.remainingAmount),
            ),
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Present: ${record.presentDays}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Half Days: ${record.halfDays}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Absent: ${record.absentDays}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_isLoadingHistory) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_salaryRecords.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 35),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                'No salary history found',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _salaryRecords.map(_buildSalaryCard).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary History'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEmployeeSelector(),
              const SizedBox(height: 22),
              if (_selectedEmployee != null) ...[
                _buildSummary(),
                const SizedBox(height: 25),
                const Text(
                  'Salary Records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _buildHistory(),
              ] else if (!_isLoadingEmployees) ...[
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    'Salary history dekhne ke liye employee select karo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
