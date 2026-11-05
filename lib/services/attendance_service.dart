import '../database/database_helper.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  AttendanceService._();

  static final AttendanceService instance = AttendanceService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  static const List<String> attendanceStatuses = [
    AttendanceModel.present,
    AttendanceModel.absent,
    AttendanceModel.halfDay,
    AttendanceModel.paidLeave,
  ];

  // Mark or update attendance
  Future<int> markAttendance(
    AttendanceModel attendance,
  ) async {
    if (!attendanceStatuses.contains(attendance.status)) {
      throw ArgumentError('Invalid attendance status.');
    }

    final db = await _databaseHelper.database;

    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      // Check whether attendance already exists
      final existing = await txn.query(
        'attendance',
        where: 'employee_id = ? AND attendance_date = ?',
        whereArgs: [
          attendance.employeeId,
          attendance.attendanceDate,
        ],
        limit: 1,
      );

      final attendanceData = attendance.toMap();

      attendanceData.remove('id');
      attendanceData['updated_at'] = now;

      if (existing.isNotEmpty) {
        // Update existing attendance
        return await txn.update(
          'attendance',
          attendanceData,
          where: 'employee_id = ? AND attendance_date = ?',
          whereArgs: [
            attendance.employeeId,
            attendance.attendanceDate,
          ],
        );
      }

      // Insert new attendance
      attendanceData['created_at'] = now;

      return await txn.insert(
        'attendance',
        attendanceData,
      );
    });
  }

  // Get attendance for a specific date
  Future<List<AttendanceModel>> getAttendanceByDate(
    String date,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'attendance',
      where: 'attendance_date = ?',
      whereArgs: [date],
      orderBy: 'employee_id ASC',
    );

    return result
        .map((map) => AttendanceModel.fromMap(map))
        .toList();
  }

  // Get attendance history of an employee
  Future<List<AttendanceModel>> getEmployeeAttendance(
    int employeeId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'attendance',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
      orderBy: 'attendance_date DESC',
    );

    return result
        .map((map) => AttendanceModel.fromMap(map))
        .toList();
  }

  // Get monthly attendance of an employee
  Future<List<AttendanceModel>> getMonthlyAttendance({
    required int employeeId,
    required int month,
    required int year,
  }) async {
    final db = await _databaseHelper.database;

    final startDate = _formatDate(DateTime(year, month, 1));
    final endDate = _formatDate(DateTime(year, month + 1, 1));

    final result = await db.query(
      'attendance',
      where: '''
        employee_id = ?
        AND attendance_date >= ?
        AND attendance_date < ?
      ''',
      whereArgs: [
        employeeId,
        startDate,
        endDate,
      ],
      orderBy: 'attendance_date ASC',
    );

    return result
        .map((map) => AttendanceModel.fromMap(map))
        .toList();
  }

  // Get attendance record for one employee and date
  Future<AttendanceModel?> getAttendanceForEmployeeDate({
    required int employeeId,
    required String date,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'attendance',
      where: 'employee_id = ? AND attendance_date = ?',
      whereArgs: [
        employeeId,
        date,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AttendanceModel.fromMap(result.first);
  }

  // Delete attendance record
  Future<int> deleteAttendance(int attendanceId) async {
    final db = await _databaseHelper.database;

    return await db.delete(
      'attendance',
      where: 'id = ?',
      whereArgs: [attendanceId],
    );
  }

  // Get monthly attendance summary
  Future<Map<String, int>> getMonthlyAttendanceSummary({
    required int employeeId,
    required int month,
    required int year,
  }) async {
    final records = await getMonthlyAttendance(
      employeeId: employeeId,
      month: month,
      year: year,
    );

    int present = 0;
    int absent = 0;
    int halfDay = 0;
    int paidLeave = 0;

    for (final record in records) {
      switch (record.status) {
        case AttendanceModel.present:
          present++;
          break;

        case AttendanceModel.absent:
          absent++;
          break;

        case AttendanceModel.halfDay:
          halfDay++;
          break;

        case AttendanceModel.paidLeave:
          paidLeave++;
          break;
      }
    }

    return {
      'present': present,
      'absent': absent,
      'half_day': halfDay,
      'paid_leave': paidLeave,
      'total_records': records.length,
    };
  }

  // Format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
} 