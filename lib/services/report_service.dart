import '../database/database_helper.dart';

class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Daily expense report
  Future<Map<String, dynamic>> getDailyExpenseReport(
    DateTime date,
  ) async {
    final db = await _databaseHelper.database;

    final formattedDate = _formatDate(date);

    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total_expenses,
        COALESCE(SUM(amount), 0) AS total_amount
      FROM expenses
      WHERE expense_date >= ?
      AND expense_date < ?
      AND deleted_at IS NULL
      ''',
      [
        formattedDate,
        _formatDate(date.add(const Duration(days: 1))),
      ],
    );

    return result.first;
  }

  // Monthly expense report
  Future<Map<String, dynamic>> getMonthlyExpenseReport({
    required int month,
    required int year,
  }) async {
    final db = await _databaseHelper.database;

    final startDate = _formatDate(DateTime(year, month, 1));
    final endDate = _formatDate(DateTime(year, month + 1, 1));

    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total_expenses,
        COALESCE(SUM(amount), 0) AS total_amount
      FROM expenses
      WHERE expense_date >= ?
      AND expense_date < ?
      AND deleted_at IS NULL
      ''',
      [startDate, endDate],
    );

    return result.first;
  }

  // Yearly expense report
  Future<Map<String, dynamic>> getYearlyExpenseReport(
    int year,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total_expenses,
        COALESCE(SUM(amount), 0) AS total_amount
      FROM expenses
      WHERE expense_date >= ?
      AND expense_date < ?
      AND deleted_at IS NULL
      ''',
      [
        '$year-01-01',
        '${year + 1}-01-01',
      ],
    );

    return result.first;
  }

  // Category-wise expense report
  Future<List<Map<String, dynamic>>> getCategoryExpenseReport({
    required int month,
    required int year,
  }) async {
    final db = await _databaseHelper.database;

    final startDate = _formatDate(DateTime(year, month, 1));
    final endDate = _formatDate(DateTime(year, month + 1, 1));

    return await db.rawQuery(
      '''
      SELECT
        category,
        COUNT(*) AS total_entries,
        COALESCE(SUM(amount), 0) AS total_amount
      FROM expenses
      WHERE expense_date >= ?
      AND expense_date < ?
      AND deleted_at IS NULL
      GROUP BY category
      ORDER BY total_amount DESC
      ''',
      [startDate, endDate],
    );
  }

  // Employee details report
  Future<List<Map<String, dynamic>>> getEmployeeReport({
    bool includeInactive = true,
  }) async {
    final db = await _databaseHelper.database;

    return await db.query(
      'employees',
      where: includeInactive
          ? 'deleted_at IS NULL'
          : "status = 'Active' AND deleted_at IS NULL",
      orderBy: 'name ASC',
    );
  }

  // Employee attendance report
  Future<List<Map<String, dynamic>>> getAttendanceReport({
    required int month,
    required int year,
    int? employeeId,
  }) async {
    final db = await _databaseHelper.database;

    final startDate = _formatDate(DateTime(year, month, 1));
    final endDate = _formatDate(DateTime(year, month + 1, 1));

    if (employeeId != null) {
      return await db.rawQuery(
        '''
        SELECT
          attendance.*,
          employees.name AS employee_name,
          employees.mobile AS employee_mobile
        FROM attendance
        INNER JOIN employees
        ON attendance.employee_id = employees.id
        WHERE attendance.attendance_date >= ?
        AND attendance.attendance_date < ?
        AND attendance.employee_id = ?
        ORDER BY attendance.attendance_date ASC
        ''',
        [startDate, endDate, employeeId],
      );
    }

    return await db.rawQuery(
      '''
      SELECT
        attendance.*,
        employees.name AS employee_name,
        employees.mobile AS employee_mobile
      FROM attendance
      INNER JOIN employees
      ON attendance.employee_id = employees.id
      WHERE attendance.attendance_date >= ?
      AND attendance.attendance_date < ?
      ORDER BY employees.name ASC,
      attendance.attendance_date ASC
      ''',
      [startDate, endDate],
    );
  }

  // Monthly attendance summary
  Future<List<Map<String, dynamic>>> getAttendanceSummary({
    required int month,
    required int year,
  }) async {
    final db = await _databaseHelper.database;

    final startDate = _formatDate(DateTime(year, month, 1));
    final endDate = _formatDate(DateTime(year, month + 1, 1));

    return await db.rawQuery(
      '''
      SELECT
        employees.id AS employee_id,
        employees.name AS employee_name,
        COUNT(attendance.id) AS total_records,
        SUM(CASE WHEN attendance.status = 'Present'
            THEN 1 ELSE 0 END) AS present_days,
        SUM(CASE WHEN attendance.status = 'Absent'
            THEN 1 ELSE 0 END) AS absent_days,
        SUM(CASE WHEN attendance.status = 'Half Day'
            THEN 1 ELSE 0 END) AS half_days,
        SUM(CASE WHEN attendance.status = 'Paid Leave'
            THEN 1 ELSE 0 END) AS unpaid_leave_days
      FROM employees
      LEFT JOIN attendance
      ON employees.id = attendance.employee_id
      AND attendance.attendance_date >= ?
      AND attendance.attendance_date < ?
      WHERE employees.deleted_at IS NULL
      GROUP BY employees.id
      ORDER BY employees.name ASC
      ''',
      [startDate, endDate],
    );
  }

  // Monthly salary report
  Future<List<Map<String, dynamic>>> getSalaryReport({
    required int month,
    required int year,
  }) async {
    final db = await _databaseHelper.database;

    return await db.rawQuery(
      '''
      SELECT
        salary_records.*,
        employees.name AS employee_name,
        employees.mobile AS employee_mobile
      FROM salary_records
      INNER JOIN employees
      ON salary_records.employee_id = employees.id
      WHERE salary_records.salary_month = ?
      AND salary_records.salary_year = ?
      ORDER BY employees.name ASC
      ''',
      [month, year],
    );
  }

  // Barcode history report
  Future<List<Map<String, dynamic>>> getBarcodeReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;

    if (startDate == null && endDate == null) {
      return await db.query(
        'barcodes',
        orderBy: 'scanned_at DESC',
      );
    }

    final start = startDate == null
        ? '0000-01-01'
        : _formatDate(startDate);

    final end = endDate == null
        ? null
        : _formatDate(endDate.add(const Duration(days: 1)));

    if (end == null) {
      return await db.query(
        'barcodes',
        where: 'scanned_at >= ?',
        whereArgs: [start],
        orderBy: 'scanned_at DESC',
      );
    }

    return await db.query(
      'barcodes',
      where: 'scanned_at >= ? AND scanned_at < ?',
      whereArgs: [start, end],
      orderBy: 'scanned_at DESC',
    );
  }

  // Date formatting: yyyy-MM-dd
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}