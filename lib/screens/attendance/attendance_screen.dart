import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/employee_model.dart';
import '../../models/attendance_model.dart';
import '../../services/employee_service.dart';
import '../../services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final EmployeeService _employeeService = EmployeeService.instance;
  final AttendanceService _attendanceService =
      AttendanceService.instance;

  DateTime _selectedDate = DateTime.now();

  List<EmployeeModel> _employees = [];
  Map<int, String> _attendanceStatus = {};

  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _statuses = [
    AttendanceModel.present,
    AttendanceModel.absent,
    AttendanceModel.halfDay,
    AttendanceModel.paidLeave,
  ];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  String _dateKey(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employees = await _employeeService.getActiveEmployees();

      final records = await _attendanceService
          .getAttendanceByDate(_dateKey(_selectedDate));

      final Map<int, String> statusMap = {};

      for (final record in records) {
        statusMap[record.employeeId] = record.status;
      }

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _attendanceStatus = statusMap;

        for (final employee in employees) {
          if (employee.id != null) {
            _attendanceStatus.putIfAbsent(
              employee.id!,
              () => AttendanceModel.absent,
            );
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load attendance.');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });

    await _loadAttendance();
  }

  void _changeStatus(int employeeId, String status) {
    setState(() {
      _attendanceStatus[employeeId] = status;
    });
  }

  Future<void> _saveAttendance() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      for (final employee in _employees) {
        if (employee.id == null) continue;

        final record = AttendanceModel(
          employeeId: employee.id!,
          attendanceDate: _dateKey(_selectedDate),
          status: _attendanceStatus[employee.id!] ??
              AttendanceModel.absent,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        await _attendanceService.markAttendance(record);
      }

      if (!mounted) return;

      _showMessage('Attendance saved successfully.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to save attendance.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int _countStatus(String status) {
    return _attendanceStatus.values
        .where((value) => value == status)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadAttendance,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDateSelector(),
            _buildSummary(),
            Expanded(
              child: _buildEmployeeList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _employees.isEmpty || _isLoading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveAttendance,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 19,
                            width: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Attendance',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
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
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: _selectDate,
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
                      'Attendance Date',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _dateKey(_selectedDate),
                      style: const TextStyle(
                        fontSize: 15,
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

  Widget _summaryItem(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 4,
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
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_employees.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 60,
                color: AppTheme.textSecondary,
              ),
              SizedBox(height: 14),
              Text(
                'No Active Employees',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Add an active employee to mark attendance.',
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: _employees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final employee = _employees[index];
        final employeeId = employee.id!;

        final selectedStatus =
            _attendanceStatus[employeeId] ?? AttendanceModel.absent;

        return _buildEmployeeCard(
          employee: employee,
          selectedStatus: selectedStatus,
        );
      },
    );
  }

  Widget _buildEmployeeCard({
    required EmployeeModel employee,
    required String selectedStatus,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.12),
                child: Text(
                  employee.name.isNotEmpty
                      ? employee.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.mobile,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 7,
            runSpacing: 8,
            children: _statuses.map((status) {
              final selected = selectedStatus == status;

              return ChoiceChip(
                label: Text(status),
                selected: selected,
                onSelected: (_) {
                  _changeStatus(employee.id!, status);
                },
                selectedColor: _statusColor(status),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : null,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
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