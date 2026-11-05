import '../database/database_helper.dart';
import '../models/employee_model.dart';

class EmployeeService {
  EmployeeService._();

  static final EmployeeService instance = EmployeeService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Add new employee
  Future<int> addEmployee(EmployeeModel employee) async {
    final db = await _databaseHelper.database;

    final now = DateTime.now().toIso8601String();

    final employeeData = employee.toMap();

    employeeData.remove('id');
    employeeData['created_at'] = now;
    employeeData['updated_at'] = now;
    employeeData['deleted_at'] = null;

    return await db.insert(
      'employees',
      employeeData,
    );
  }

  // Get all employees
  Future<List<EmployeeModel>> getAllEmployees() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'employees',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );

    return result
        .map((map) => EmployeeModel.fromMap(map))
        .toList();
  }

  // Get active employees
  Future<List<EmployeeModel>> getActiveEmployees() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'employees',
      where: 'status = ? AND deleted_at IS NULL',
      whereArgs: ['Active'],
      orderBy: 'name ASC',
    );

    return result
        .map((map) => EmployeeModel.fromMap(map))
        .toList();
  }

  // Get inactive employees
  Future<List<EmployeeModel>> getInactiveEmployees() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'employees',
      where: 'status = ? AND deleted_at IS NULL',
      whereArgs: ['Inactive'],
      orderBy: 'name ASC',
    );

    return result
        .map((map) => EmployeeModel.fromMap(map))
        .toList();
  }

  // Get employee by ID
  Future<EmployeeModel?> getEmployeeById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'employees',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return EmployeeModel.fromMap(result.first);
  }

  // Search employees by name or mobile
  Future<List<EmployeeModel>> searchEmployees(String query) async {
    final db = await _databaseHelper.database;

    final searchQuery = '%${query.trim()}%';

    final result = await db.query(
      'employees',
      where: '''
        deleted_at IS NULL
        AND (name LIKE ? OR mobile LIKE ?)
      ''',
      whereArgs: [
        searchQuery,
        searchQuery,
      ],
      orderBy: 'name ASC',
    );

    return result
        .map((map) => EmployeeModel.fromMap(map))
        .toList();
  }

  // Update employee
  Future<int> updateEmployee(EmployeeModel employee) async {
    if (employee.id == null) {
      throw ArgumentError('Employee ID is required for update.');
    }

    final db = await _databaseHelper.database;

    final employeeData = employee.toMap();

    employeeData.remove('id');
    employeeData.remove('created_at');
    employeeData['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'employees',
      employeeData,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [employee.id],
    );
  }

  // Change employee status
  Future<int> updateEmployeeStatus(
    int employeeId,
    String status,
  ) async {
    if (status != 'Active' && status != 'Inactive') {
      throw ArgumentError('Invalid employee status.');
    }

    final db = await _databaseHelper.database;

    return await db.update(
      'employees',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [employeeId],
    );
  }

  // Soft delete employee
  // Attendance and salary history will remain محفوظ.
  Future<int> deleteEmployee(int employeeId) async {
    final db = await _databaseHelper.database;

    final now = DateTime.now().toIso8601String();

    return await db.update(
      'employees',
      {
        'status': 'Inactive',
        'deleted_at': now,
        'updated_at': now,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [employeeId],
    );
  }

  // Get total active employee count
  Future<int> getActiveEmployeeCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM employees
      WHERE status = 'Active'
      AND deleted_at IS NULL
    ''');

    return (result.first['total'] as int?) ?? 0;
  }
}