
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../services/report_service.dart';
import '../../services/export_service.dart';
import '../../services/barcode_service.dart';

enum ReportType {
  expenses,
  employees,
  attendance,
  salary,
  barcode,
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService.instance;
  final ExportService _exportService = ExportService.instance;
  final BarcodeService _barcodeService = BarcodeService.instance;

  ReportType _selectedReport = ReportType.expenses;
  DateTime _selectedMonth = DateTime.now();

  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _expenseSummary;

  bool _isLoading = false;
  bool _isExporting = false;
  String? _error;

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  String get _monthLabel =>
      DateFormat('MMMM yyyy').format(_selectedMonth);

  String _amount(dynamic value) {
    final number = value is num ? value.toDouble() : 0.0;
    return _currency.format(number);
  }

  double _number(dynamic value) {
    return value is num ? value.toDouble() : 0.0;
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _records = [];
      _expenseSummary = null;
    });

    try {
      final month = _selectedMonth.month;
      final year = _selectedMonth.year;

      switch (_selectedReport) {
        case ReportType.expenses:
          final summary = await _reportService.getMonthlyExpenseReport(
            month: month,
            year: year,
          );
          final categories =
              await _reportService.getCategoryExpenseReport(
            month: month,
            year: year,
          );

          if (!mounted) return;

          setState(() {
            _expenseSummary = summary;
            _records = categories;
          });
          break;

        case ReportType.employees:
          final employees =
              await _reportService.getEmployeeReport(
            includeInactive: true,
          );

          if (!mounted) return;
          setState(() => _records = employees);
          break;

        case ReportType.attendance:
          final attendance =
              await _reportService.getAttendanceSummary(
            month: month,
            year: year,
          );

          if (!mounted) return;
          setState(() => _records = attendance);
          break;

        case ReportType.salary:
          final salaries = await _reportService.getSalaryReport(
            month: month,
            year: year,
          );

          if (!mounted) return;
          setState(() => _records = salaries);
          break;

        case ReportType.barcode:
          final barcodes = await _reportService.getBarcodeReport();

          if (!mounted) return;
          setState(() => _records = barcodes);
          break;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Report load nahi ho payi: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectReport(ReportType type) {
    setState(() {
      _selectedReport = type;
    });
    _loadReport();
  }

  Future<void> _changeMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select a date in the required month',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });

    _loadReport();
  }

  String _reportTitle() {
    switch (_selectedReport) {
      case ReportType.expenses:
        return 'Expense Report';
      case ReportType.employees:
        return 'Employee Report';
      case ReportType.attendance:
        return 'Attendance Report';
      case ReportType.salary:
        return 'Salary Report';
      case ReportType.barcode:
        return 'Barcode Report';
    }
  }

  IconData _reportIcon(ReportType type) {
    switch (type) {
      case ReportType.expenses:
        return Icons.account_balance_wallet_outlined;
      case ReportType.employees:
        return Icons.people_outline;
      case ReportType.attendance:
        return Icons.event_available_outlined;
      case ReportType.salary:
        return Icons.payments_outlined;
      case ReportType.barcode:
        return Icons.qr_code_scanner;
    }
  }

  Widget _buildReportSelector() {
    final reports = [
      (ReportType.expenses, 'Expenses'),
      (ReportType.employees, 'Employees'),
      (ReportType.attendance, 'Attendance'),
      (ReportType.salary, 'Salary'),
      (ReportType.barcode, 'Barcode'),
    ];

    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final type = reports[index].$1;
          final label = reports[index].$2;
          final selected = type == _selectedReport;

          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => _selectReport(type),
            avatar: Icon(
              _reportIcon(type),
              size: 17,
              color: selected ? Colors.white : AppTheme.primary,
            ),
            selectedColor: AppTheme.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : null,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    if (_selectedReport == ReportType.employees ||
        _selectedReport == ReportType.barcode) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: _changeMonth,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _monthLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSummary() {
    if (_expenseSummary == null) {
      return const SizedBox.shrink();
    }

    final total = _expenseSummary!['total_amount'] ?? 0;
    final count = _expenseSummary!['total_expenses'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Total Expenses',
            _amount(total),
            Icons.currency_rupee,
            AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'Entries',
            '$count',
            Icons.receipt_long_outlined,
            AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
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
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _dateText(dynamic value) {
    if (value == null) return '-';

    try {
      return DateFormat('dd MMM yyyy')
          .format(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    switch (_selectedReport) {
      case ReportType.expenses:
        return _buildExpenseCard(record);
      case ReportType.employees:
        return _buildEmployeeCard(record);
      case ReportType.attendance:
        return _buildAttendanceCard(record);
      case ReportType.salary:
        return _buildSalaryCard(record);
      case ReportType.barcode:
        return _buildBarcodeCard(record);
    }
  }

  Widget _buildExpenseCard(Map<String, dynamic> record) {
    return _recordCard(
      icon: Icons.category_outlined,
      title: record['category']?.toString() ?? 'Other',
      subtitle: '${record['total_entries'] ?? 0} expense entries',
      trailing: _amount(record['total_amount']),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> record) {
    final status = record['status']?.toString() ?? 'Inactive';

    return _recordCard(
      icon: Icons.person_outline,
      title: record['name']?.toString() ?? 'Employee',
      subtitle: '${record['mobile'] ?? '-'} • $status',
      trailing: _amount(record['basic_salary']),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    return _recordCard(
      icon: Icons.event_available_outlined,
      title: record['employee_name']?.toString() ?? 'Employee',
      subtitle:
          'Present: ${record['present_days'] ?? 0}  •  '
          'Absent: ${record['absent_days'] ?? 0}\n'
          'Half Day: ${record['half_days'] ?? 0}  •  '
          'Unpaid Leave: ${record['unpaid_leave_days'] ?? 0}',
      trailing: '${record['total_records'] ?? 0} records',
    );
  }

  Widget _buildSalaryCard(Map<String, dynamic> record) {
    final status = record['status']?.toString() ?? 'Pending';

    return _recordCard(
      icon: Icons.payments_outlined,
      title: record['employee_name']?.toString() ?? 'Employee',
      subtitle:
          'Paid: ${_amount(record['paid_amount'])}\nStatus: $status',
      trailing: _amount(record['final_payable']),
    );
  }

  String _dateTimeText(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  Widget _buildBarcodeCard(Map<String, dynamic> record) {
    final id = int.tryParse(record['id']?.toString() ?? '');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.10),
          child: const Icon(
            Icons.qr_code_2,
            color: AppTheme.primary,
          ),
        ),
        title: Text(
          record['barcode_number']?.toString() ?? '-',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            'Scanned: ${_dateTimeText(record['scanned_at'])}',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        trailing: id == null
            ? const SizedBox.shrink()
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _editBarcodeRecord(record),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.primary,
                    ),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: () => _deleteBarcodeRecord(record),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.danger,
                    ),
                    tooltip: 'Delete',
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _editBarcodeRecord(
    Map<String, dynamic> record,
  ) async {
    final id = int.tryParse(record['id']?.toString() ?? '');
    if (id == null) return;

    final controller = TextEditingController(
      text: record['barcode_number']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final updatedNumber = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Barcode'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Barcode Number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Barcode number required';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(
                    dialogContext,
                    controller.text.trim(),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (updatedNumber == null || !mounted) return;

    try {
      await _barcodeService.updateBarcode(id, updatedNumber);

      if (!mounted) return;

      _showMessage(
        'Barcode update ho gaya.',
        color: AppTheme.success,
      );
      await _loadReport();
    } on StateError catch (e) {
      if (!mounted) return;
      _showMessage(e.message, color: AppTheme.danger);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Update failed: $e', color: AppTheme.danger);
    }
  }

  Future<void> _deleteBarcodeRecord(
    Map<String, dynamic> record,
  ) async {
    final id = int.tryParse(record['id']?.toString() ?? '');
    if (id == null) return;

    final number = record['barcode_number']?.toString() ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Barcode?'),
          content: Text(
            'Kya aap barcode "$number" delete karna chahte hain?',
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
        );
      },
    );

    if (confirm != true) return;

    try {
      await _barcodeService.deleteBarcode(id);

      if (!mounted) return;

      _showMessage(
        'Barcode delete ho gaya.',
        color: AppTheme.success,
      );
      await _loadReport();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Delete failed: $e', color: AppTheme.danger);
    }
  }

  Widget _recordCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 7,
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.10),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        trailing: Text(
          trailing,
          textAlign: TextAlign.end,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<String> _exportHeaders() {
    switch (_selectedReport) {
      case ReportType.expenses:
        return ['Category', 'Total Entries', 'Total Amount'];

      case ReportType.employees:
        return [
          'Name',
          'Mobile',
          'Address',
          'Joining Date',
          'Basic Salary',
          'Status',
        ];

      case ReportType.attendance:
        return [
          'Employee',
          'Total Records',
          'Present',
          'Absent',
          'Half Day',
          'Unpaid Leave',
        ];

      case ReportType.salary:
        return [
          'Employee',
          'Mobile',
          'Basic Salary',
          'Payable Days',
          'Final Salary',
          'Paid Amount',
          'Pending Amount',
          'Status',
        ];

      case ReportType.barcode:
        return ['Barcode Number', 'Scanned At'];
    }
  }

  List<List<String>> _exportRows() {
    switch (_selectedReport) {
      case ReportType.expenses:
        return _records.map((record) {
          return [
            record['category']?.toString() ?? 'Other',
            record['total_entries']?.toString() ?? '0',
            _amount(record['total_amount']),
          ];
        }).toList();

      case ReportType.employees:
        return _records.map((record) {
          return [
            record['name']?.toString() ?? '',
            record['mobile']?.toString() ?? '',
            record['address']?.toString() ?? '',
            _dateText(record['joining_date']),
            _amount(record['basic_salary']),
            record['status']?.toString() ?? '',
          ];
        }).toList();

      case ReportType.attendance:
        return _records.map((record) {
          return [
            record['employee_name']?.toString() ?? '',
            record['total_records']?.toString() ?? '0',
            record['present_days']?.toString() ?? '0',
            record['absent_days']?.toString() ?? '0',
            record['half_days']?.toString() ?? '0',
            record['unpaid_leave_days']?.toString() ?? '0',
          ];
        }).toList();

      case ReportType.salary:
        return _records.map((record) {
          final finalPayable = _number(record['final_payable']);
          final paidAmount = _number(record['paid_amount']);

          return [
            record['employee_name']?.toString() ?? '',
            record['employee_mobile']?.toString() ?? '',
            _amount(record['basic_salary']),
            record['payable_days']?.toString() ?? '0',
            _amount(finalPayable),
            _amount(paidAmount),
            _amount(finalPayable - paidAmount),
            record['status']?.toString() ?? '',
          ];
        }).toList();

      case ReportType.barcode:
        return _records.map((record) {
          return [
            record['barcode_number']?.toString() ?? '',
            _dateTimeText(record['scanned_at']),
          ];
        }).toList();
    }
  }

  Future<void> _exportReport({required bool pdf}) async {
    if (_isLoading || _isExporting) return;

    if (_records.isEmpty) {
      _showMessage('Export karne ke liye report data available nahi hai.');
      return;
    }

    setState(() => _isExporting = true);

    try {
      final headers = _exportHeaders();
      final rows = _exportRows();

      final title = _selectedReport == ReportType.employees ||
              _selectedReport == ReportType.barcode
          ? _reportTitle()
          : '${_reportTitle()} - $_monthLabel';

      final path = pdf
          ? await _exportService.exportToPdf(
              title: title,
              headers: headers,
              rows: rows,
            )
          : await _exportService.exportToExcel(
              title: title,
              headers: headers,
              rows: rows,
            );

      if (!mounted) return;

      _showMessage(
        '${pdf ? 'PDF' : 'Excel'} report saved successfully:\n$path',
        color: AppTheme.success,
        duration: 6,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Export failed: $e',
        color: AppTheme.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showMessage(
    String message, {
    Color? color,
    int duration = 3,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: Duration(seconds: duration),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isExporting
                ? null
                : () => _exportReport(pdf: true),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isExporting
                ? null
                : () => _exportReport(pdf: false),
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Export Excel'),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(35),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 45,
                color: AppTheme.danger,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _loadReport,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 45),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.insert_chart_outlined,
                size: 50,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No report data available',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _records.map(_buildRecordCard).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports'),
        actions: [
          IconButton(
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Report',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 13),
              _buildReportSelector(),
              const SizedBox(height: 18),
              _buildMonthSelector(),
              const SizedBox(height: 20),
              if (_selectedReport == ReportType.expenses) ...[
                _buildExpenseSummary(),
                const SizedBox(height: 22),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _reportTitle(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isExporting)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 13),
              _buildContent(),
              if (!_isLoading &&
                  _error == null &&
                  _records.isNotEmpty) ...[
                const SizedBox(height: 18),
                _buildExportButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
