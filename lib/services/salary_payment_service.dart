import '../database/database_helper.dart';
import '../models/salary_model.dart';
import '../models/salary_payment_model.dart';

class SalaryPaymentService {
  SalaryPaymentService._();

  static final SalaryPaymentService instance =
      SalaryPaymentService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Record a salary payment
  Future<int> addPayment({
    required int salaryRecordId,
    required double amount,
    required String paymentDate,
    required String paymentMethod,
    String? note,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }

    const allowedMethods = [
      SalaryPaymentModel.cash,
      SalaryPaymentModel.upi,
      SalaryPaymentModel.bank,
    ];

    if (!allowedMethods.contains(paymentMethod)) {
      throw ArgumentError('Invalid payment method.');
    }

    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // Get salary record
      final salaryResult = await txn.query(
        'salary_records',
        where: 'id = ?',
        whereArgs: [salaryRecordId],
        limit: 1,
      );

      if (salaryResult.isEmpty) {
        throw Exception('Salary record not found.');
      }

      final salary = SalaryModel.fromMap(salaryResult.first);

      final remainingAmount = salary.finalPayable - salary.paidAmount;

      if (amount > remainingAmount) {
        throw ArgumentError(
          'Payment amount cannot exceed remaining salary.',
        );
      }

      final now = DateTime.now().toIso8601String();

      // Create payment record
      final payment = SalaryPaymentModel(
        salaryRecordId: salaryRecordId,
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        note: note,
        createdAt: now,
      );

      final paymentId = await txn.insert(
        'salary_payments',
        payment.toMap(),
      );

      // Update total paid amount
      final updatedPaidAmount = salary.paidAmount + amount;

      final updatedStatus = updatedPaidAmount >= salary.finalPayable
          ? SalaryModel.paid
          : SalaryModel.partial;

      await txn.update(
        'salary_records',
        {
          'paid_amount': updatedPaidAmount,
          'status': updatedStatus,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [salaryRecordId],
      );

      return paymentId;
    });
  }

  // Get all payments for a salary record
  Future<List<SalaryPaymentModel>> getPaymentsBySalaryId(
    int salaryRecordId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'salary_payments',
      where: 'salary_record_id = ?',
      whereArgs: [salaryRecordId],
      orderBy: 'payment_date DESC, id DESC',
    );

    return result
        .map((map) => SalaryPaymentModel.fromMap(map))
        .toList();
  }

  // Get payment history for an employee
  Future<List<SalaryPaymentModel>> getEmployeePaymentHistory(
    int employeeId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT payments.*
      FROM salary_payments AS payments
      INNER JOIN salary_records AS salaries
      ON payments.salary_record_id = salaries.id
      WHERE salaries.employee_id = ?
      ORDER BY payments.payment_date DESC, payments.id DESC
      ''',
      [employeeId],
    );

    return result
        .map((map) => SalaryPaymentModel.fromMap(map))
        .toList();
  }

  // Get total amount paid to an employee
  Future<double> getTotalPaidToEmployee(
    int employeeId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(payments.amount), 0) AS total
      FROM salary_payments AS payments
      INNER JOIN salary_records AS salaries
      ON payments.salary_record_id = salaries.id
      WHERE salaries.employee_id = ?
      ''',
      [employeeId],
    );

    return (result.first['total'] as num).toDouble();
  }

  // Get total salary paid in a month
  Future<double> getMonthlyTotalPaid({
    required int month,
    required int year,
  }) async {
    final db = await _databaseHelper.database;

    final startDate = _formatDate(DateTime(year, month, 1));
    final endDate = _formatDate(DateTime(year, month + 1, 1));

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM salary_payments
      WHERE payment_date >= ?
      AND payment_date < ?
      ''',
      [
        startDate,
        endDate,
      ],
    );

    return (result.first['total'] as num).toDouble();
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

  // Format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}