
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/employee_model.dart';
import '../../models/salary_model.dart';
import '../../services/export_service.dart';

class SalarySlipScreen extends StatefulWidget {
  final EmployeeModel employee;
  final SalaryModel salary;

  const SalarySlipScreen({
    super.key,
    required this.employee,
    required this.salary,
  });

  @override
  State<SalarySlipScreen> createState() => _SalarySlipScreenState();
}

class _SalarySlipScreenState extends State<SalarySlipScreen> {
  bool _isExporting = false;

  String get _monthName {
    return DateFormat('MMMM yyyy').format(
      DateTime(
        widget.salary.salaryYear,
        widget.salary.salaryMonth,
      ),
    );
  }

  String _money(double value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(value);
  }

  double get _pendingAmount {
    final pending = widget.salary.finalPayable -
        widget.salary.paidAmount;

    return pending > 0 ? pending : 0;
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);

    try {
      final salary = widget.salary;
      final employee = widget.employee;

      final headers = ['Description', 'Amount'];

      final rows = <List<String>>[
        ['Basic Salary', _money(salary.basicSalary)],
        ['Bonus', _money(salary.bonus)],
        ['Gross Salary', _money(salary.grossSalary)],
        ['Advance Deduction', _money(salary.advanceDeduction)],
        ['Other Deduction', _money(salary.otherDeduction)],
        ['Final Payable', _money(salary.finalPayable)],
        ['Amount Paid', _money(salary.paidAmount)],
        ['Pending Amount', _money(_pendingAmount)],
      ];

      final attendanceHeaders = [
        'Attendance Details',
        'Days',
      ];

      final attendanceRows = <List<String>>[
        ['Total Working Days', '${salary.totalWorkingDays}'],
        ['Present Days', '${salary.presentDays}'],
        ['Half Days', '${salary.halfDays}'],
        ['Absent Days', '${salary.absentDays}'],
        ['Unpaid Leave', '${salary.unpaidLeaveDays}'],
        ['Payable Days', '${salary.payableDays}'],
        ['Daily Rate', _money(salary.dailyRate)],
      ];

      await ExportService.instance.exportToPdf(
        title: 'Salary Slip - $_monthName',
        headers: headers,
        rows: [
          ['Employee', employee.name],
          ['Mobile', employee.mobile],
          ['Salary Month', _monthName],
          ...rows,
          ['', ''],
          ...attendanceHeaders.isNotEmpty
              ? [
                  ['Attendance Details', 'Days'],
                  ...attendanceRows,
                ]
              : [],
        ],
        fileName:
            'salary_slip_${employee.id}_${salary.salaryMonth}_${salary.salaryYear}',
      );

      if (!mounted) return;

      _showMessage('Salary slip PDF exported successfully.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to export salary slip.');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _infoRow(
    String title,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _totalCard(
    String title,
    String amount,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 9),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salary = widget.salary;
    final employee = widget.employee;

    final statusColor = salary.isPaid
        ? AppTheme.success
        : salary.isPartial
            ? AppTheme.warning
            : AppTheme.danger;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Salary Slip'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isExporting ? null : _exportPdf,
            tooltip: 'Export PDF',
            icon: _isExporting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3563E9),
                    Color(0xFF2449B8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.business_center_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'BUSINESS MANAGER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'SALARY SLIP • $_monthName',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _section(
              title: 'Employee Information',
              children: [
                _infoRow('Employee Name', employee.name),
                _infoRow('Mobile Number', employee.mobile),
                _infoRow('Joining Date', employee.joiningDate),
                _infoRow('Employee Status', employee.status),
              ],
            ),

            _section(
              title: 'Attendance Details',
              children: [
                _infoRow(
                  'Total Working Days',
                  '${salary.totalWorkingDays}',
                ),
                _infoRow('Present Days', '${salary.presentDays}'),
                _infoRow('Half Days', '${salary.halfDays}'),
                _infoRow('Absent Days', '${salary.absentDays}'),
                _infoRow(
                  'Unpaid Leave',
                  '${salary.unpaidLeaveDays}',
                ),
                _infoRow(
                  'Payable Days',
                  '${salary.payableDays}',
                  bold: true,
                  valueColor: AppTheme.success,
                ),
                _infoRow(
                  'Daily Salary Rate',
                  _money(salary.dailyRate),
                ),
              ],
            ),

            _section(
              title: 'Salary Calculation',
              children: [
                _infoRow(
                  'Basic Salary',
                  _money(salary.basicSalary),
                ),
                _infoRow(
                  'Bonus',
                  '+ ${_money(salary.bonus)}',
                  valueColor: AppTheme.success,
                ),
                _infoRow(
                  'Gross Salary',
                  _money(salary.grossSalary),
                  bold: true,
                ),
                const Divider(),
                _infoRow(
                  'Advance Deduction',
                  '- ${_money(salary.advanceDeduction)}',
                  valueColor: AppTheme.danger,
                ),
                _infoRow(
                  'Other Deduction',
                  '- ${_money(salary.otherDeduction)}',
                  valueColor: AppTheme.danger,
                ),
                const Divider(),
                _infoRow(
                  'Final Payable Salary',
                  _money(salary.finalPayable),
                  bold: true,
                  valueColor: AppTheme.primary,
                ),
              ],
            ),

            Row(
              children: [
                _totalCard(
                  'Paid Amount',
                  _money(salary.paidAmount),
                  AppTheme.success,
                ),
                const SizedBox(width: 12),
                _totalCard(
                  'Pending Amount',
                  _money(_pendingAmount),
                  AppTheme.danger,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Payment Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      salary.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(
                  _isExporting
                      ? 'Exporting...'
                      : 'Export Salary Slip PDF',
                ),
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child: Text(
                'Generated by Business Manager',
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
