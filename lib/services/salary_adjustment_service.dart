import '../database/database_helper.dart';
import '../models/salary_adjustment_model.dart';

class SalaryAdjustmentService {
  SalaryAdjustmentService._();

  static final SalaryAdjustmentService instance =
      SalaryAdjustmentService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Add salary adjustment
  Future<int> addAdjustment(
    SalaryAdjustmentModel adjustment,
  ) async {
    if (adjustment.employeeId <= 0) {
      throw ArgumentError('Valid employee ID is required.');
    }

    if (adjustment.salaryMonth < 1 ||
        adjustment.salaryMonth > 12) {
      throw ArgumentError('Invalid salary month.');
    }

    if (adjustment.amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    const allowedTypes = [
      SalaryAdjustmentModel.bonus,
      SalaryAdjustmentModel.advance,
      SalaryAdjustmentModel.deduction,
    ];

    if (!allowedTypes.contains(adjustment.adjustmentType)) {
      throw ArgumentError('Invalid adjustment type.');
    }

    final db = await _databaseHelper.database;

    final employee = await db.query(
      'employees',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [adjustment.employeeId],
      limit: 1,
    );

    if (employee.isEmpty) {
      throw Exception('Employee not found.');
    }

    final data = adjustment.toMap();

    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();

    return await db.insert(
      'salary_adjustments',
      data,
    );
  }

  // Get all adjustments for an employee
  Future<List<SalaryAdjustmentModel>> getEmployeeAdjustments(
    int employeeId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'salary_adjustments',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
      orderBy: 'salary_year DESC, salary_month DESC, id DESC',
    );

    return result
        .map((map) => SalaryAdjustmentModel.fromMap(map))
        .toList();
  }

  // Get adjustments for a particular month
  Future<List<SalaryAdjustmentModel>> getMonthlyAdjustments({
    required int employeeId,
    required int month,
    required int year,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'salary_adjustments',
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
      orderBy: 'id DESC',
    );

    return result
        .map((map) => SalaryAdjustmentModel.fromMap(map))
        .toList();
  }

  // Get adjustment totals for a particular month
  Future<Map<String, double>> getMonthlyAdjustmentTotals({
    required int employeeId,
    required int month,
    required int year,
  }) async {
    final adjustments = await getMonthlyAdjustments(
      employeeId: employeeId,
      month: month,
      year: year,
    );

    double bonus = 0;
    double advance = 0;
    double deduction = 0;

    for (final item in adjustments) {
      switch (item.adjustmentType) {
        case SalaryAdjustmentModel.bonus:
          bonus += item.amount;
          break;

        case SalaryAdjustmentModel.advance:
          advance += item.amount;
          break;

        case SalaryAdjustmentModel.deduction:
          deduction += item.amount;
          break;
      }
    }

    return {
      'bonus': bonus,
      'advance': advance,
      'deduction': deduction,
    };
  }

  // Delete an adjustment
  Future<int> deleteAdjustment(int adjustmentId) async {
    final db = await _databaseHelper.database;

    return await db.delete(
      'salary_adjustments',
      where: 'id = ?',
      whereArgs: [adjustmentId],
    );
  }
}