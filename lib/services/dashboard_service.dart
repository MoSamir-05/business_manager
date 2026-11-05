import '../database/database_helper.dart';

class DashboardService {
  DashboardService._();

  static final DashboardService instance = DashboardService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Convert dd-MM-yyyy into yyyy-MM-dd for SQL date comparison.
  String get _normalizedExpenseDateSql => '''
    CASE
      WHEN length(expense_date) = 10
        AND substr(expense_date, 3, 1) = '-'
      THEN
        substr(expense_date, 7, 4) || '-' ||
        substr(expense_date, 4, 2) || '-' ||
        substr(expense_date, 1, 2)
      ELSE substr(expense_date, 1, 10)
    END
  ''';

  // Get complete dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final db = await _databaseHelper.database;

    final now = DateTime.now();

    final today = _formatDate(now);
    final displayToday = _formatDisplayDate(now);

    final monthStart = _formatDate(
      DateTime(now.year, now.month, 1),
    );

    final nextMonthStart = _formatDate(
      DateTime(now.year, now.month + 1, 1),
    );

    // Active employees
    final employeeResult = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM employees
      WHERE status = 'Active'
      AND deleted_at IS NULL
    ''');

    final totalEmployees =
        (employeeResult.first['total'] as num).toInt();

    // Today's attendance summary
    final attendanceResult = await db.rawQuery(
      '''
      SELECT
        SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END)
          AS present,
        SUM(CASE WHEN status = 'Absent' THEN 1 ELSE 0 END)
          AS absent,
        SUM(CASE WHEN status = 'Half Day' THEN 1 ELSE 0 END)
          AS half_day,
        SUM(CASE WHEN status = 'Paid Leave' THEN 1 ELSE 0 END)
          AS paid_leave
      FROM attendance
      WHERE attendance_date IN (?, ?)
      ''',
      [today, displayToday],
    );

    final attendance = attendanceResult.first;

    final presentToday =
        (attendance['present'] as num?)?.toInt() ?? 0;

    final absentToday =
        (attendance['absent'] as num?)?.toInt() ?? 0;

    final halfDayToday =
        (attendance['half_day'] as num?)?.toInt() ?? 0;

    final paidLeaveToday =
        (attendance['paid_leave'] as num?)?.toInt() ?? 0;

    // Current month expenses - supports both date formats
    final expenseResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE $_normalizedExpenseDateSql >= ?
      AND $_normalizedExpenseDateSql < ?
      AND deleted_at IS NULL
      ''',
      [monthStart, nextMonthStart],
    );

    final monthlyExpenses =
        (expenseResult.first['total'] as num).toDouble();

    // Pending salary amount
    final salaryResult = await db.rawQuery('''
      SELECT COALESCE(
        SUM(
          CASE
            WHEN final_payable > paid_amount
            THEN final_payable - paid_amount
            ELSE 0
          END
        ),
        0
      ) AS total
      FROM salary_records
    ''');

    final pendingSalary =
        (salaryResult.first['total'] as num).toDouble();

    // Total saved barcodes
    final barcodeResult = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM barcodes
    ''');

    final totalBarcodes =
        (barcodeResult.first['total'] as num).toInt();

    return {
      'total_employees': totalEmployees,
      'present_today': presentToday,
      'absent_today': absentToday,
      'half_day_today': halfDayToday,
      'paid_leave_today': paidLeaveToday,
      'monthly_expenses': monthlyExpenses,
      'pending_salary': pendingSalary,
      'total_barcodes': totalBarcodes,
      'today_date': today,
      'month': now.month,
      'year': now.year,
    };
  }

  // Get recent expense activities
  Future<List<Map<String, dynamic>>> getRecentExpenses({
    int limit = 5,
  }) async {
    final db = await _databaseHelper.database;

    return await db.query(
      'expenses',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  // Get today's attendance records
  Future<List<Map<String, dynamic>>> getTodayAttendance() async {
    final db = await _databaseHelper.database;

    final now = DateTime.now();

    final today = _formatDate(now);
    final displayToday = _formatDisplayDate(now);

    return await db.rawQuery(
      '''
      SELECT
        attendance.id,
        attendance.employee_id,
        attendance.attendance_date,
        attendance.status,
        employees.name AS employee_name
      FROM attendance
      INNER JOIN employees
      ON attendance.employee_id = employees.id
      WHERE attendance.attendance_date IN (?, ?)
      ORDER BY employees.name ASC
      ''',
      [today, displayToday],
    );
  }

  // Get monthly expense chart data
  Future<List<Map<String, dynamic>>> getMonthlyExpenseChart({
    required int year,
  }) async {
    final db = await _databaseHelper.database;

    return await db.rawQuery(
      '''
      SELECT
        CAST(
          substr($_normalizedExpenseDateSql, 6, 2)
          AS INTEGER
        ) AS month,
        COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE substr($_normalizedExpenseDateSql, 1, 4) = ?
      AND deleted_at IS NULL
      GROUP BY month
      ORDER BY month ASC
      ''',
      [year.toString()],
    );
  }

  // Get category-wise expense chart data
  Future<List<Map<String, dynamic>>> getExpenseCategoryChart() async {
    final db = await _databaseHelper.database;

    return await db.rawQuery('''
      SELECT
        category,
        COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE deleted_at IS NULL
      GROUP BY category
      ORDER BY total DESC
    ''');
  }

  // Format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // Format date as dd-MM-yyyy
  String _formatDisplayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }
}