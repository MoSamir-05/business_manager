
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../core/constants/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance =
      DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  // Initialize Database
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      AppConstants.databaseName,
    );

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Enable Foreign Keys
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Create All Tables
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Employees Table
    batch.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        photo_path TEXT,
        name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        address TEXT NOT NULL,
        joining_date TEXT NOT NULL,
        basic_salary REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'Active',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    // 2. Expenses Table
    batch.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        expense_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        receipt_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    // 3. Attendance Table
    batch.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        attendance_date TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (employee_id)
          REFERENCES employees(id)
          ON DELETE RESTRICT,
        UNIQUE(employee_id, attendance_date)
      )
    ''');

    // 4. Salary Records Table
    batch.execute('''
      CREATE TABLE salary_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        salary_month INTEGER NOT NULL,
        salary_year INTEGER NOT NULL,
        basic_salary REAL NOT NULL,
        total_working_days INTEGER NOT NULL,
        present_days REAL NOT NULL DEFAULT 0,
        half_days REAL NOT NULL DEFAULT 0,
        absent_days REAL NOT NULL DEFAULT 0,
        unpaid_leave_days REAL NOT NULL DEFAULT 0,
        payable_days REAL NOT NULL DEFAULT 0,
        daily_rate REAL NOT NULL DEFAULT 0,
        gross_salary REAL NOT NULL DEFAULT 0,
        bonus REAL NOT NULL DEFAULT 0,
        advance_deduction REAL NOT NULL DEFAULT 0,
        other_deduction REAL NOT NULL DEFAULT 0,
        final_payable REAL NOT NULL DEFAULT 0,
        paid_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'Pending',
        salary_stage TEXT NOT NULL DEFAULT 'Final',
        generated_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (employee_id)
          REFERENCES employees(id)
          ON DELETE RESTRICT,
        UNIQUE(employee_id, salary_month, salary_year)
      )
    ''');

    // 5. Salary Payments Table
    batch.execute('''
      CREATE TABLE salary_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        salary_record_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (salary_record_id)
          REFERENCES salary_records(id)
          ON DELETE RESTRICT
      )
    ''');

    // 6. Salary Adjustments Table
    batch.execute('''
      CREATE TABLE salary_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        salary_month INTEGER NOT NULL,
        salary_year INTEGER NOT NULL,
        adjustment_type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (employee_id)
          REFERENCES employees(id)
          ON DELETE RESTRICT
      )
    ''');

    // 7. Barcode Table
    batch.execute('''
      CREATE TABLE barcodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode_number TEXT NOT NULL UNIQUE,
        scanned_at TEXT NOT NULL
      )
    ''');

    // 8. App Settings Table
    batch.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setting_key TEXT NOT NULL UNIQUE,
        setting_value TEXT,
        updated_at TEXT
      )
    ''');

    // 9. Backup History Table
    batch.execute('''
      CREATE TABLE backup_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL,
        file_size INTEGER,
        backup_type TEXT NOT NULL,
        backup_status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Database Indexes
    batch.execute('''
      CREATE INDEX idx_employee_status
      ON employees(status)
    ''');

    batch.execute('''
      CREATE INDEX idx_expense_date
      ON expenses(expense_date)
    ''');

    batch.execute('''
      CREATE INDEX idx_attendance_date
      ON attendance(attendance_date)
    ''');

    batch.execute('''
      CREATE INDEX idx_attendance_employee
      ON attendance(employee_id)
    ''');

    batch.execute('''
      CREATE INDEX idx_salary_month_year
      ON salary_records(salary_month, salary_year)
    ''');

    batch.execute('''
      CREATE INDEX idx_salary_payments_record
      ON salary_payments(salary_record_id)
    ''');

    batch.execute('''
      CREATE INDEX idx_barcode_number
      ON barcodes(barcode_number)
    ''');

    await batch.commit(noResult: true);
  }

  // Handle Database Upgrades
  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Version 1 to Version 2
    if (oldVersion < 2 && newVersion >= 2) {
      final columns = await db.rawQuery(
        'PRAGMA table_info(salary_records)',
      );

      final hasSalaryStage = columns.any(
        (column) => column['name'] == 'salary_stage',
      );

      if (!hasSalaryStage) {
        await db.execute('''
          ALTER TABLE salary_records
          ADD COLUMN salary_stage TEXT
          NOT NULL DEFAULT 'Final'
        ''');
      }
    }
  }

  // Get Database Path
  Future<String> getDatabasePath() async {
    return await getDatabasesPath().then(
      (directory) => join(
        directory,
        AppConstants.databaseName,
      ),
    );
  }

  // Close Database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
