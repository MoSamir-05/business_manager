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

  // Generate or recalculate monthly salary
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

    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      final startDate = _formatDate(DateTime(year, month, 1));
      final endDate = _formatDate(DateTime(year, month + 1, 1));

      // Get configured non-working dates
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
          final decoded = jsonDecode(
            settingResult.first['setting_value'] as String,
          );

          if (decoded is List) {
            nonWorkingDates.addAll(
              decoded.whereType<String>(),
            );
          }
        } catch (_) {
          throw FormatException(
            'Invalid non-working dates configuration.',
          );
        }
      }

      // Calculate actual working days
      final daysInMonth = DateTime(year, month + 1, 0).day;

      int totalWorkingDays = 0;

      for (int day = 1; day <= daysInMonth; day++) {
        final date = _formatDate(DateTime(year, month, day));

        if (!nonWorkingDates.contains(date)) {
          totalWorkingDays++;
        }
      }

      // Get attendance records
      final attendanceResult = await txn.query(
        'attendance',
        where: '''
          employee_id = ?
          AND attendance_date >= ?
          AND attendance_date < ?
        ''',
        whereArgs: [
          employee.id,
          startDate,
          endDate,
        ],
      );

      int presentDays = 0;
      int halfDays = 0;
      int paidLeaveDays = 0;

      for (final row in attendanceResult) {
        final attendanceDate = row['attendance_date'] as String;

        // Ignore attendance on configured non-working dates
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
            break;
        }
      }

      // Unmarked working days are also counted as absent
      final absentDays = (
        totalWorkingDays -
        presentDays -
        halfDays -
        paidLeaveDays
      ).clamp(0, totalWorkingDays);

      // Salary calculation
      final dailyRate = totalWorkingDays > 0
          ? employee.basicSalary / totalWorkingDays
          : 0.0;

      final payableDays = presentDays + (halfDays * 0.5);

      final grossSalary = payableDays * dailyRate;

      // Get salary adjustments
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
        final amount = (adjustment['amount'] as num).toDouble();

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
          grossSalary + bonus - advanceDeduction - otherDeduction;

      final finalPayable =
          calculatedPayable > 0 ? calculatedPayable : 0.0;

      // Check existing salary record
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

      final existingPaidAmount = existingResult.isNotEmpty
          ? (existingResult.first['paid_amount'] as num).toDouble()
          : 0.0;

      // Preserve previous payments
      final paidAmount = existingPaidAmount > finalPayable
          ? finalPayable
          : existingPaidAmount;

      final status = _getPaymentStatus(
        finalPayable,
        paidAmount,
      );

      final now = DateTime.now().toIso8601String();

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
        'generated_at': now,
        'updated_at': now,
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

      final savedSalary = await txn.query(
        'salary_records',
        where: 'id = ?',
        whereArgs: [salaryId],
        limit: 1,
      );

      return SalaryModel.fromMap(savedSalary.first);
    });
  }

  // Get salary by employee and month
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

  // Get all salary records for a month
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

  // Get employee salary history
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

  // Get total pending salary
  Future<double> getTotalPendingSalary() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(
        SUM(final_payable - paid_amount), 0
      ) AS total
      FROM salary_records
      WHERE final_payable > paid_amount
    ''');

    return (result.first['total'] as num).toDouble();
  }

  // Calculate payment status
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

  // Format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}