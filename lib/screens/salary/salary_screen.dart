import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/employee_model.dart';
import '../../models/salary_model.dart';
import '../../services/employee_service.dart';
import '../../services/salary_service.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final EmployeeService _employeeService = EmployeeService.instance;
  final SalaryService _salaryService = SalaryService.instance;

  DateTime _selectedMonth = DateTime.now();

  List<EmployeeModel> _employees = [];
  List<SalaryModel> _salaryRecords = [];

  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadSalaryData();
  }

  String get _monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  Future<void> _loadSalaryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employees = await _employeeService.getAllEmployees();

      final records = await _salaryService.getMonthlySalaryRecords(
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      );

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _salaryRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load salary records.');
    }
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select a date in the salary month',
    );

    if (picked == null) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });

    await _loadSalaryData();
  }

  Future<void> _generateSalary() async {
    if (_isGenerating) return;

    final activeEmployees = _employees
        .where((employee) => employee.status == 'Active')
        .toList();

    if (activeEmployees.isEmpty) {
      _showMessage('No active employees found.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Generate Monthly Salary?'),
          content: Text(
            'Generate salary for ${activeEmployees.length} active '
            'employees for $_monthName?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      for (final employee in activeEmployees) {
        await _salaryService.generateMonthlySalary(
          employee: employee,
          month: _selectedMonth.month,
          year: _selectedMonth.year,
        );
      }

      await _loadSalaryData();

      if (!mounted) return;

      _showMessage('Monthly salary generated successfully.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to generate salary. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  String _employeeName(int employeeId) {
    for (final employee in _employees) {
      if (employee.id == employeeId) {
        return employee.name;
      }
    }

    return 'Employee #$employeeId';
  }

  int _countStatus(String status) {
    return _salaryRecords.where((record) {
      return record.status == status;
    }).length;
  }

  double _totalPayable() {
    return _salaryRecords.fold(
      0,
      (total, record) => total + record.finalPayable,
    );
  }

  double _totalPaid() {
    return _salaryRecords.fold(
      0,
      (total, record) => total + record.paidAmount,
    );
  }

  double _totalPending() {
    return _salaryRecords.fold(
      0,
      (total, record) {
        final pending = record.finalPayable - record.paidAmount;
        return total + (pending > 0 ? pending : 0);
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Salary Management',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadSalaryData,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadSalaryData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                  children: [
                    _buildMonthSelector(),
                    const SizedBox(height: 18),
                    _buildSummary(),
                    const SizedBox(height: 22),
                    _buildGenerateButton(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(),
                    const SizedBox(height: 13),
                    _buildSalaryList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return InkWell(
      onTap: _selectMonth,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.primary,
              size: 25,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Salary Month',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _monthName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _summaryCard(
              'Total Salary',
              _totalPayable(),
              AppTheme.primary,
              Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(width: 10),
            _summaryCard(
              'Paid',
              _totalPaid(),
              AppTheme.success,
              Icons.check_circle_outline_rounded,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _summaryCard(
              'Pending',
              _totalPending(),
              AppTheme.warning,
              Icons.pending_actions_rounded,
            ),
            const SizedBox(width: 10),
            _summaryCountCard(
              'Employees',
              _salaryRecords.length,
              AppTheme.info,
              Icons.people_outline_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _statusCount('Paid', _countStatus('Paid'), AppTheme.success),
            const SizedBox(width: 8),
            _statusCount(
              'Partial',
              _countStatus('Partial'),
              AppTheme.warning,
            ),
            const SizedBox(width: 8),
            _statusCount(
              'Pending',
              _countStatus('Pending'),
              AppTheme.danger,
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCountCard(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCount(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: _isGenerating ? null : _generateSalary,
        icon: _isGenerating
            ? const SizedBox(
                height: 19,
                width: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.calculate_rounded),
        label: Text(
          _isGenerating ? 'Generating Salary...' : 'Generate Monthly Salary',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Employee Salary Records',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '${_salaryRecords.length} Records',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSalaryList() {
    if (_salaryRecords.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 55,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 14),
            Text(
              'No Salary Records',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Generate monthly salary to see employee records here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _salaryRecords.map((record) {
        return _buildSalaryCard(record);
      }).toList(),
    );
  }

  Widget _buildSalaryCard(SalaryModel record) {
    final pending = record.finalPayable - record.paidAmount;

    final statusColor = record.status == 'Paid'
        ? AppTheme.success
        : record.status == 'Partial'
            ? AppTheme.warning
            : AppTheme.danger;

    return InkWell(
      onTap: () {
        _showSalaryDetails(record);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _employeeName(record.employeeId),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _salaryInfo(
                  'Basic Salary',
                  record.basicSalary,
                ),
                _salaryInfo(
                  'Final Salary',
                  record.finalPayable,
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                _salaryInfo(
                  'Paid Amount',
                  record.paidAmount,
                ),
                _salaryInfo(
                  'Pending Amount',
                  pending > 0 ? pending : 0,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payable Days: ${record.payableDays}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const Text(
                  'View Details',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _salaryInfo(String title, double amount) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showSalaryDetails(SalaryModel record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Salary Breakdown',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _employeeName(record.employeeId),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _detailRow(
                    'Basic Salary',
                    record.basicSalary,
                  ),
                  _detailRow(
                    'Total Working Days',
                    record.totalWorkingDays,
                    isAmount: false,
                  ),
                  _detailRow(
                    'Present Days',
                    record.presentDays,
                    isAmount: false,
                  ),
                  _detailRow(
                    'Half Days',
                    record.halfDays,
                    isAmount: false,
                  ),
                  _detailRow(
                    'Absent Days',
                    record.absentDays,
                    isAmount: false,
                  ),
                  _detailRow(
                    'Unpaid Leave Days',
                    record.unpaidLeaveDays,
                    isAmount: false,
                  ),
                  _detailRow(
                    'Payable Days',
                    record.payableDays,
                    isAmount: false,
                  ),
                  _detailRow(
                    'Daily Rate',
                    record.dailyRate,
                  ),
                  _detailRow(
                    'Gross Salary',
                    record.grossSalary,
                  ),
                  _detailRow(
                    'Bonus',
                    record.bonus,
                  ),
                  _detailRow(
                    'Advance Deduction',
                    record.advanceDeduction,
                  ),
                  _detailRow(
                    'Other Deduction',
                    record.otherDeduction,
                  ),
                  const Divider(height: 25),
                  _detailRow(
                    'Final Payable',
                    record.finalPayable,
                    bold: true,
                  ),
                  _detailRow(
                    'Already Paid',
                    record.paidAmount,
                  ),
                  _detailRow(
                    'Remaining Amount',
                    record.finalPayable - record.paidAmount,
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String title,
    num value, {
    bool isAmount = true,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            isAmount
                ? '₹${value.toStringAsFixed(2)}'
                : value.toString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}