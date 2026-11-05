import '../database/database_helper.dart';
import '../models/expense_model.dart';

class ExpenseService {
  ExpenseService._();

  static final ExpenseService instance = ExpenseService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Add new expense
  Future<int> addExpense(ExpenseModel expense) async {
    final db = await _databaseHelper.database;

    final now = DateTime.now().toIso8601String();

    final expenseData = expense.toMap();

    expenseData.remove('id');
    expenseData['created_at'] = now;
    expenseData['updated_at'] = now;
    expenseData['deleted_at'] = null;

    return await db.insert(
      'expenses',
      expenseData,
    );
  }

  // Get all expenses
  Future<List<ExpenseModel>> getAllExpenses() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'expenses',
      where: 'deleted_at IS NULL',
      orderBy: 'expense_date DESC, id DESC',
    );

    return result
        .map((map) => ExpenseModel.fromMap(map))
        .toList();
  }

  // Get expense by ID
  Future<ExpenseModel?> getExpenseById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'expenses',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return ExpenseModel.fromMap(result.first);
  }

  // Update expense
  Future<int> updateExpense(ExpenseModel expense) async {
    if (expense.id == null) {
      throw ArgumentError('Expense ID is required for update.');
    }

    final db = await _databaseHelper.database;

    final expenseData = expense.toMap();

    expenseData.remove('id');
    expenseData.remove('created_at');
    expenseData['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'expenses',
      expenseData,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [expense.id],
    );
  }

  // Soft delete expense
  Future<int> deleteExpense(int expenseId) async {
    final db = await _databaseHelper.database;

    final now = DateTime.now().toIso8601String();

    return await db.update(
      'expenses',
      {
        'deleted_at': now,
        'updated_at': now,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [expenseId],
    );
  }

  // Search expenses by title or category
  Future<List<ExpenseModel>> searchExpenses(String query) async {
    final db = await _databaseHelper.database;

    final searchQuery = '%${query.trim()}%';

    final result = await db.query(
      'expenses',
      where: '''
        deleted_at IS NULL
        AND (title LIKE ? OR category LIKE ?)
      ''',
      whereArgs: [
        searchQuery,
        searchQuery,
      ],
      orderBy: 'expense_date DESC',
    );

    return result
        .map((map) => ExpenseModel.fromMap(map))
        .toList();
  }

  // Get expenses for a specific date
  Future<List<ExpenseModel>> getExpensesByDate(
    String date,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'expenses',
      where: 'expense_date LIKE ? AND deleted_at IS NULL',
      whereArgs: ['$date%'],
      orderBy: 'id DESC',
    );

    return result
        .map((map) => ExpenseModel.fromMap(map))
        .toList();
  }

  // Get expenses for a specific month and year
  Future<List<ExpenseModel>> getMonthlyExpenses(
    int month,
    int year,
  ) async {
    final db = await _databaseHelper.database;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final result = await db.query(
      'expenses',
      where: '''
        expense_date >= ?
        AND expense_date < ?
        AND deleted_at IS NULL
      ''',
      whereArgs: [
        _formatDate(startDate),
        _formatDate(endDate),
      ],
      orderBy: 'expense_date DESC',
    );

    return result
        .map((map) => ExpenseModel.fromMap(map))
        .toList();
  }

  // Get yearly expenses
  Future<List<ExpenseModel>> getYearlyExpenses(int year) async {
    final db = await _databaseHelper.database;

    final startDate = '$year-01-01';
    final endDate = '${year + 1}-01-01';

    final result = await db.query(
      'expenses',
      where: '''
        expense_date >= ?
        AND expense_date < ?
        AND deleted_at IS NULL
      ''',
      whereArgs: [
        startDate,
        endDate,
      ],
      orderBy: 'expense_date DESC',
    );

    return result
        .map((map) => ExpenseModel.fromMap(map))
        .toList();
  }

  // Get total expense amount
  Future<double> getTotalExpenses() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE deleted_at IS NULL
    ''');

    return (result.first['total'] as num).toDouble();
  }

  // Get monthly expense amount
  Future<double> getMonthlyExpenseTotal(
    int month,
    int year,
  ) async {
    final db = await _databaseHelper.database;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE expense_date >= ?
      AND expense_date < ?
      AND deleted_at IS NULL
      ''',
      [
        _formatDate(startDate),
        _formatDate(endDate),
      ],
    );

    return (result.first['total'] as num).toDouble();
  }

  // Get category-wise expense totals
  Future<Map<String, double>> getCategoryWiseTotals() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT category, SUM(amount) AS total
      FROM expenses
      WHERE deleted_at IS NULL
      GROUP BY category
      ORDER BY total DESC
    ''');

    final Map<String, double> totals = {};

    for (final row in result) {
      totals[row['category'] as String] =
          (row['total'] as num).toDouble();
    }

    return totals;
  }

  // Format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}