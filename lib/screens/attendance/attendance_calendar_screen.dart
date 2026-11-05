import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../models/employee_model.dart';
import '../../services/attendance_service.dart';
import '../../services/employee_service.dart';

class AttendanceCalendarScreen extends StatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  State<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends State<AttendanceCalendarScreen> {
  final AttendanceService _attendanceService =
      AttendanceService.instance;

  final EmployeeService _employeeService =
      EmployeeService.instance;

  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  List<EmployeeModel> _employees = [];
  List<AttendanceModel> _records = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  String _dateKey(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employees = await _employeeService.getAllEmployees();

      final List<AttendanceModel> records = [];

      for (final employee in employees) {
        if (employee.id == null) continue;

        final monthlyRecords =
            await _attendanceService.getMonthlyAttendance(
          employeeId: employee.id!,
          month: _currentMonth.month,
          year: _currentMonth.year,
        );

        records.addAll(monthlyRecords);
      }

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load calendar data.');
    }
  }

  Future<void> _changeMonth(int difference) async {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + difference,
      );

      _selectedDate = DateTime(
        _currentMonth.year,
        _currentMonth.month,
        1,
      );
    });

    await _loadCalendarData();
  }

  List<AttendanceModel> _recordsForDate(DateTime date) {
    final key = _dateKey(date);

    return _records.where((record) {
      return record.attendanceDate == key;
    }).toList();
  }

  int _countForDate(DateTime date, String status) {
    return _recordsForDate(date)
        .where((record) => record.status == status)
        .length;
  }

  Color _dayColor(DateTime date) {
    final records = _recordsForDate(date);

    if (records.isEmpty) {
      return Colors.transparent;
    }

    final present = records
        .where((r) => r.status == AttendanceModel.present)
        .length;

    final absent = records
        .where((r) => r.status == AttendanceModel.absent)
        .length;

    final halfDay = records
        .where((r) => r.status == AttendanceModel.halfDay)
        .length;

    final leave = records
        .where((r) => r.status == AttendanceModel.paidLeave)
        .length;

    final categories = [
      present,
      absent,
      halfDay,
      leave,
    ].where((count) => count > 0).length;

    if (categories > 1) return AppTheme.info;
    if (present > 0) return AppTheme.success;
    if (absent > 0) return AppTheme.danger;
    if (halfDay > 0) return AppTheme.warning;
    if (leave > 0) return AppTheme.info;

    return Colors.transparent;
  }

  String _monthName(int month) {
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

    return months[month - 1];
  }

  String _employeeName(int employeeId) {
    for (final employee in _employees) {
      if (employee.id == employeeId) {
        return employee.name;
      }
    }

    return 'Employee #$employeeId';
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
          'Attendance Calendar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadCalendarData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMonthHeader(),
                  const SizedBox(height: 18),
                  _buildCalendar(),
                  const SizedBox(height: 20),
                  _buildLegend(),
                  const SizedBox(height: 25),
                  _buildSelectedDateDetails(),
                ],
              ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _monthName(_currentMonth.month),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _currentMonth.year.toString(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );

    final totalDays = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;

    final startingOffset = firstDay.weekday - 1;
    final totalCells = ((startingOffset + totalDays + 6) ~/ 7) * 7;

    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 13),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 4,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - startingOffset + 1;

              if (dayNumber < 1 || dayNumber > totalDays) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                dayNumber,
              );

              return _buildDayCell(date);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final selected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;

    final color = _dayColor(date);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      borderRadius: BorderRadius.circular(11),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: selected
              ? Border.all(
                  color: AppTheme.primary,
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.w800
                    : FontWeight.w500,
                color: selected ? AppTheme.primary : null,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 17,
      runSpacing: 12,
      children: [
        _legendItem('Present', AppTheme.success),
        _legendItem('Absent', AppTheme.danger),
        _legendItem('Half Day', AppTheme.warning),
        _legendItem('Leave', AppTheme.info),
        _legendItem('Mixed', AppTheme.info),
      ],
    );
  }

  Widget _legendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 9,
          width: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateDetails() {
    final records = _recordsForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance - ${_dateKey(_selectedDate)}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 13),
        if (records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'No attendance records for this date.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          )
        else ...[
          Row(
            children: [
              _countCard(
                'Present',
                _countForDate(
                  _selectedDate,
                  AttendanceModel.present,
                ),
                AppTheme.success,
              ),
              const SizedBox(width: 8),
              _countCard(
                'Absent',
                _countForDate(
                  _selectedDate,
                  AttendanceModel.absent,
                ),
                AppTheme.danger,
              ),
              const SizedBox(width: 8),
              _countCard(
                'Half Day',
                _countForDate(
                  _selectedDate,
                  AttendanceModel.halfDay,
                ),
                AppTheme.warning,
              ),
              const SizedBox(width: 8),
              _countCard(
                'Leave',
                _countForDate(
                  _selectedDate,
                  AttendanceModel.paidLeave,
                ),
                AppTheme.info,
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...records.map(_buildEmployeeRecord),
        ],
      ],
    );
  }

  Widget _countCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 3,
        ),
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
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeRecord(AttendanceModel record) {
    final color = _statusColor(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _employeeName(record.employeeId),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            record.status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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