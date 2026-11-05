import '../database/database_helper.dart';

class DashboardService {
  DashboardService._();

  static final DashboardService instance = DashboardService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Get complete dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final db = await _databaseHelper.database;

    final now = DateTime.now();

    final today = _formatDate(now);
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
      WHERE attendance_date = ?
      ''',
      [today],
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

    // Current month expenses
    final expenseResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE expense_date >= ?
      AND expense_date < ?
      AND deleted_at IS NULL
      ''',
      [
        monthStart,
        nextMonthStart,
      ],
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

    final result = await db.query(
      'expenses',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return result;
  }

  // Get today's attendance records
  Future<List<Map<String, dynamic>>> getTodayAttendance() async {
    final db = await _databaseHelper.database;

    final today = _formatDate(DateTime.now());

    final result = await db.rawQuery(
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
      WHERE attendance.attendance_date = ?
      ORDER BY employees.name ASC
      ''',
      [today],
    );

    return result;
  }

  // Get monthly expense chart data
  Future<List<Map<String, dynamic>>> getMonthlyExpenseChart({
    required int year,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT
        CAST(
          strftime('%m', expense_date) AS INTEGER
        ) AS month,
        COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE expense_date >= ?
      AND expense_date < ?
      AND deleted_at IS NULL
      GROUP BY strftime('%m', expense_date)
      ORDER BY month ASC
      ''',
      [
        '$year-01-01',
        '${year + 1}-01-01',
      ],
    );

    return result;
  }

  // Get category-wise expense chart data
  Future<List<Map<String, dynamic>>> getExpenseCategoryChart() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT
        category,
        COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE deleted_at IS NULL
      GROUP BY category
      ORDER BY total DESC
    ''');

    return result;
  }

  // Format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}