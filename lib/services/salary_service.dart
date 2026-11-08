
import 'dart:convert';

import '../database/database_helper.dart';
import '../models/salary_model.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../models/salary_adjustment_model.dart';

class SalaryService {
  SalaryService._();

  static final SalaryService instance = SalaryService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Generate or recalculate monthly salary.
  // Current month = Provisional.
  // Completed month = Final.
  Future<SalaryModel> generateMonthlySalary({
    required EmployeeModel employee,
    required int month,
    required int year,
  }) async {
    if (employee.id == null) {
      throw ArgumentError('Valid employee ID is required.');
    }

    if (month < 1 || month > 12) {
      throw ArgumentError('Invalid salary month.');
    }

    if (year < 2000) {
      throw ArgumentError('Invalid salary year.');
    }

    final now = DateTime.now();
    final requestedMonth = DateTime(year, month);
    final currentMonth = DateTime(now.year, now.month);

    if (requestedMonth.isAfter(currentMonth)) {
      throw ArgumentError(
        'Future month salary cannot be generated.',
      );
    }

    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0);

      // Current month cutoff is today.
      // Completed months use their last day.
      final calculationEnd = requestedMonth.isAtSameMomentAs(
        currentMonth,
      )
          ? DateTime(now.year, now.month, now.day)
          : monthEnd;

      // Parse employee joining date.
      final joiningDate = _parseEmployeeDate(
        employee.joiningDate,
      );

      final effectiveStart = joiningDate.isAfter(monthStart)
          ? joiningDate
          : monthStart;

      // Employee has not joined during this salary month.
      if (effectiveStart.isAfter(monthEnd)) {
        throw ArgumentError(
          'Employee joining date is after the selected salary month.',
        );
      }

      // Get configured non-working dates.
      final settingKey =
          'non_working_dates_${year}_${month.toString().padLeft(2, '0')}';

      final settingResult = await txn.query(
        'app_settings',
        columns: ['setting_value'],
        where: 'setting_key = ?',
        whereArgs: [settingKey],
        limit: 1,
      );

      final Set<String> nonWorkingDates = {};

      if (settingResult.isNotEmpty) {
        try {
          final settingValue =
              settingResult.first['setting_value'];

          if (settingValue != null) {
            final decoded = jsonDecode(
              settingValue as String,
            );

            if (decoded is List) {
              nonWorkingDates.addAll(
                decoded.whereType<String>(),
              );
            }
          }
        } catch (_) {
          throw FormatException(
            'Invalid non-working dates configuration.',
          );
        }
      }

      // Count actual working days in the eligible month.
      // No fixed weekly holiday is assumed.
      int totalWorkingDays = 0;

      for (
        DateTime date = effectiveStart;
        !date.isAfter(monthEnd);
        date = date.add(const Duration(days: 1))
      ) {
        final dateString = _formatDate(date);

        if (!nonWorkingDates.contains(dateString)) {
          totalWorkingDays++;
        }
      }

      // Count elapsed working days only.
      // Future dates are never treated as absent.
      int elapsedWorkingDays = 0;

      for (
        DateTime date = effectiveStart;
        !date.isAfter(calculationEnd);
        date = date.add(const Duration(days: 1))
      ) {
        final dateString = _formatDate(date);

        if (!nonWorkingDates.contains(dateString)) {
          elapsedWorkingDays++;
        }
      }

      // Get attendance records within eligible calculation dates.
      final attendanceResult = await txn.query(
        'attendance',
        where: '''
          employee_id = ?
          AND attendance_date >= ?
          AND attendance_date <= ?
        ''',
        whereArgs: [
          employee.id,
          _formatDate(effectiveStart),
          _formatDate(calculationEnd),
        ],
      );

      int presentDays = 0;
      int halfDays = 0;
      int paidLeaveDays = 0;
      int recordedAbsentDays = 0;

      for (final row in attendanceResult) {
        final attendanceDate =
            row['attendance_date'] as String;

        // Ignore configured non-working dates.
        if (nonWorkingDates.contains(attendanceDate)) {
          continue;
        }

        switch (row['status']) {
          case AttendanceModel.present:
            presentDays++;
            break;

          case AttendanceModel.halfDay:
            halfDays++;
            break;

          case AttendanceModel.paidLeave:
            paidLeaveDays++;
            break;

          case AttendanceModel.absent:
            recordedAbsentDays++;
            break;
        }
      }

      // Unmarked elapsed working days count as absent.
      final absentDays = (
        elapsedWorkingDays -
        presentDays -
        halfDays -
        paidLeaveDays
      ).clamp(0, elapsedWorkingDays);

      // Salary calculation.
      // Full eligible month working days are used as denominator.
      final dailyRate = totalWorkingDays > 0
          ? employee.basicSalary / totalWorkingDays
          : 0.0;

      // Half day = 0.5 payable day.
      // Paid leave is unpaid as per the finalized rule.
      final payableDays = presentDays + (halfDays * 0.5);

      final grossSalary = payableDays * dailyRate;

      // Get salary adjustments.
      final adjustments = await txn.query(
        'salary_adjustments',
        where: '''
          employee_id = ?
          AND salary_month = ?
          AND salary_year = ?
        ''',
        whereArgs: [
          employee.id,
          month,
          year,
        ],
      );

      double bonus = 0;
      double advanceDeduction = 0;
      double otherDeduction = 0;

      for (final adjustment in adjustments) {
        final amount =
            (adjustment['amount'] as num).toDouble();

        switch (adjustment['adjustment_type']) {
          case SalaryAdjustmentModel.bonus:
            bonus += amount;
            break;

          case SalaryAdjustmentModel.advance:
            advanceDeduction += amount;
            break;

          case SalaryAdjustmentModel.deduction:
            otherDeduction += amount;
            break;
        }
      }

      final calculatedPayable =
          grossSalary +
          bonus -
          advanceDeduction -
          otherDeduction;

      final finalPayable =
          calculatedPayable > 0 ? calculatedPayable : 0.0;

      // Check existing salary record.
      final existingResult = await txn.query(
        'salary_records',
        where: '''
          employee_id = ?
          AND salary_month = ?
          AND salary_year = ?
        ''',
        whereArgs: [
          employee.id,
          month,
          year,
        ],
        limit: 1,
      );

      // Preserve all previously recorded payments.
      // Never reduce paid_amount during recalculation.
      final existingPaidAmount = existingResult.isNotEmpty
          ? (existingResult.first['paid_amount'] as num)
              .toDouble()
          : 0.0;

      final paidAmount = existingPaidAmount;

      final status = _getPaymentStatus(
        finalPayable,
        paidAmount,
      );

      final salaryStage = requestedMonth.isAtSameMomentAs(
        currentMonth,
      )
          ? SalaryModel.provisional
          : SalaryModel.finalStage;

      final timestamp = DateTime.now().toIso8601String();

      final salaryData = {
        'employee_id': employee.id,
        'salary_month': month,
        'salary_year': year,
        'basic_salary': employee.basicSalary,
        'total_working_days': totalWorkingDays,
        'present_days': presentDays,
        'half_days': halfDays,
        'absent_days': absentDays,
        'unpaid_leave_days': paidLeaveDays,
        'payable_days': payableDays,
        'daily_rate': dailyRate,
        'gross_salary': grossSalary,
        'bonus': bonus,
        'advance_deduction': advanceDeduction,
        'other_deduction': otherDeduction,
        'final_payable': finalPayable,
        'paid_amount': paidAmount,
        'status': status,
        'salary_stage': salaryStage,
        'generated_at': existingResult.isNotEmpty
            ? existingResult.first['generated_at']
            : timestamp,
        'updated_at': timestamp,
      };

      int salaryId;

      if (existingResult.isNotEmpty) {
        salaryId = existingResult.first['id'] as int;

        await txn.update(
          'salary_records',
          salaryData,
          where: 'id = ?',
          whereArgs: [salaryId],
        );
      } else {
        salaryId = await txn.insert(
          'salary_records',
          salaryData,
        );
      }

      // Return the saved salary record.
      final savedSalary = await txn.query(
        'salary_records',
        where: 'id = ?',
        whereArgs: [salaryId],
        limit: 1,
      );

      if (savedSalary.isEmpty) {
        throw StateError(
          'Salary record could not be retrieved after saving.',
        );
      }

      return SalaryModel.fromMap(savedSalary.first);
    });
  }

  // Get salary by employee and month.
  Future<SalaryModel?> getSalaryByEmployeeMonth({
    required int employeeId,
    required int month,
    required int year,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'salary_records',
      where: '''
        employee_id = ?
        AND salary_month = ?
        AND salary_year = ?
      ''',
      whereArgs: [
        employeeId,
        month,
        year,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return SalaryModel.fromMap(result.first);
  }

  // Get all salary records for a month.
  Future<List<SalaryModel>> getMonthlySalaryRecords({
    required int month,
    required int year,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'salary_records',
      where: 'salary_month = ? AND salary_year = ?',
      whereArgs: [
        month,
        year,
      ],
      orderBy: 'employee_id ASC',
    );

    return result
        .map((map) => SalaryModel.fromMap(map))
        .toList();
  }

  // Get employee salary history.
  Future<List<SalaryModel>> getEmployeeSalaryHistory(
    int employeeId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'salary_records',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
      orderBy: 'salary_year DESC, salary_month DESC',
    );

    return result
        .map((map) => SalaryModel.fromMap(map))
        .toList();
  }

  // Get total pending salary.
  Future<double> getTotalPendingSalary() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(
        SUM(
          CASE
            WHEN final_payable > paid_amount
            THEN final_payable - paid_amount
            ELSE 0
          END
        ), 0
      ) AS total
      FROM salary_records
    ''');

    return (result.first['total'] as num).toDouble();
  }

  // Calculate payment status.
  String _getPaymentStatus(
    double finalPayable,
    double paidAmount,
  ) {
    if (paidAmount <= 0) {
      return SalaryModel.pending;
    }

    if (paidAmount >= finalPayable) {
      return SalaryModel.paid;
    }

    return SalaryModel.partial;
  }

  // Parse employee joining date.
  // Supports dd-MM-yyyy and yyyy-MM-dd.
  DateTime _parseEmployeeDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed != null) {
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
      );
    }

    final parts = value.split('-');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    throw FormatException(
      'Invalid employee joining date: $value',
    );
  }

  // Format date as yyyy-MM-dd.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
