import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../models/employee_model.dart';
import '../../services/attendance_service.dart';
import '../../services/employee_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends State<AttendanceHistoryScreen> {
  final AttendanceService _attendanceService =
      AttendanceService.instance;

  final EmployeeService _employeeService =
      EmployeeService.instance;

  DateTime _selectedMonth = DateTime.now();

  List<AttendanceModel> _records = [];
  List<EmployeeModel> _employees = [];

  String _selectedFilter = 'All';
  int? _selectedEmployeeId;

  bool _isLoading = true;

  final List<String> _filters = [
    'All',
    AttendanceModel.present,
    AttendanceModel.absent,
    AttendanceModel.halfDay,
    AttendanceModel.paidLeave,
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employees = await _employeeService.getAllEmployees();

      // Existing service mein monthly attendance
      // employee-wise fetch hoti hai.
      final List<AttendanceModel> allRecords = [];

      for (final employee in employees) {
        if (employee.id == null) continue;

        final employeeRecords =
            await _attendanceService.getMonthlyAttendance(
          employeeId: employee.id!,
          month: _selectedMonth.month,
          year: _selectedMonth.year,
        );

        allRecords.addAll(employeeRecords);
      }

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _records = allRecords;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load attendance history.');
    }
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select a date in the required month',
    );

    if (picked == null) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });

    await _loadHistory();
  }

  String _employeeName(int employeeId) {
    final matches = _employees.where(
      (employee) => employee.id == employeeId,
    );

    if (matches.isEmpty) {
      return 'Employee #$employeeId';
    }

    return matches.first.name;
  }

  DateTime _parseAttendanceDate(String value) {
    final parts = value.split('-');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime.tryParse(value) ?? DateTime(2000);
  }

  List<AttendanceModel> get _filteredRecords {
    final result = _records.where((record) {
      final matchesStatus = _selectedFilter == 'All' ||
          record.status == _selectedFilter;

      final matchesEmployee = _selectedEmployeeId == null ||
          record.employeeId == _selectedEmployeeId;

      return matchesStatus && matchesEmployee;
    }).toList();

    result.sort(
      (a, b) => _parseAttendanceDate(b.attendanceDate)
          .compareTo(_parseAttendanceDate(a.attendanceDate)),
    );

    return result;
  }

  int _countStatus(String status) {
    return _records
        .where((record) => record.status == status)
        .length;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildMonthSelector(),
            _buildSummary(),
            _buildEmployeeFilter(),
            _buildStatusFilters(),
            Expanded(
              child: _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthName = [
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
    ][_selectedMonth.month - 1];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: _selectMonth,
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
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$monthName ${_selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _summaryItem(
            'Present',
            _countStatus(AttendanceModel.present),
            AppTheme.success,
          ),
          const SizedBox(width: 8),
          _summaryItem(
            'Absent',
            _countStatus(AttendanceModel.absent),
            AppTheme.danger,
          ),
          const SizedBox(width: 8),
          _summaryItem(
            'Half Day',
            _countStatus(AttendanceModel.halfDay),
            AppTheme.warning,
          ),
          const SizedBox(width: 8),
          _summaryItem(
            'Leave',
            _countStatus(AttendanceModel.paidLeave),
            AppTheme.info,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    int count,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 3,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: DropdownButtonFormField<int?>(
        initialValue: _selectedEmployeeId,
        decoration: InputDecoration(
          labelText: 'Filter by Employee',
          prefixIcon: const Icon(Icons.person_outline_rounded),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('All Employees'),
          ),
          ..._employees.map(
            (employee) => DropdownMenuItem<int?>(
              value: employee.id,
              child: Text(employee.name),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedEmployeeId = value;
          });
        },
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final records = _filteredRecords;

    if (records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 58,
                color: AppTheme.textSecondary,
              ),
              SizedBox(height: 14),
              Text(
                'No Attendance Records',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'No records match the selected filters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 25),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _buildRecordCard(records[index]);
        },
      ),
    );
  }

  Widget _buildRecordCard(AttendanceModel record) {
    final color = _statusColor(record.status);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _employeeName(record.employeeId),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  record.attendanceDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case AttendanceModel.present:
        return AppTheme.success;
      case AttendanceModel.absent:
        return AppTheme.danger;
      case AttendanceModel.halfDay:
        return AppTheme.warning;
      case AttendanceModel.paidLeave:
        return AppTheme.info;
      default:
        return AppTheme.primary;
    }
  }
}