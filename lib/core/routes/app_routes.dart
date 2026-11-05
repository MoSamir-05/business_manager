
import 'package:flutter/material.dart';

// Dashboard
import '../../screens/dashboard/dashboard_screen.dart';

// Expenses
import '../../screens/expenses/expenses_screen.dart';
import '../../screens/expenses/add_expense_screen.dart';
import '../../screens/expenses/expense_details_screen.dart';
import '../../screens/expenses/expense_filter_screen.dart';

// Employees
import '../../screens/employees/employees_screen.dart';
import '../../screens/employees/add_employee_screen.dart';
import '../../screens/employees/employee_details_screen.dart';

// Attendance
import '../../screens/attendance/attendance_screen.dart';
import '../../screens/attendance/attendance_history_screen.dart';
import '../../screens/attendance/attendance_calendar_screen.dart';

// Salary
import '../../screens/salary/salary_screen.dart';
import '../../screens/salary/salary_payment_screen.dart';
import '../../screens/salary/salary_history_screen.dart';
import '../../screens/salary/salary_adjustment_screen.dart';
import '../../screens/salary/salary_slip_screen.dart';

// Barcode
import '../../screens/barcode/barcode_scanner_screen.dart';
import '../../screens/barcode/barcode_history_screen.dart';

// Reports
import '../../screens/reports/reports_screen.dart';

// Backup
import '../../screens/backup/backup_screen.dart';
import '../../screens/backup/restore_backup_screen.dart';

// Security
import '../../screens/security/pin_lock_screen.dart';
import '../../screens/security/pin_setup_screen.dart';

// Settings
import '../../screens/settings/settings_screen.dart';

// Models
import '../../models/expense_model.dart';
import '../../models/employee_model.dart';
import '../../models/salary_model.dart';

class AppRoutes {
  AppRoutes._();

  // Dashboard
  static const String dashboard = '/';

  // Expenses
  static const String expenses = '/expenses';
  static const String addExpense = '/add-expense';
  static const String expenseDetails = '/expense-details';
  static const String expenseFilter = '/expense-filter';

  // Employees
  static const String employees = '/employees';
  static const String addEmployee = '/add-employee';
  static const String employeeDetails = '/employee-details';

  // Attendance
  static const String attendance = '/attendance';
  static const String attendanceHistory = '/attendance-history';
  static const String attendanceCalendar = '/attendance-calendar';

  // Salary
  static const String salary = '/salary';
  static const String salaryDetails = '/salary-details';
  static const String salaryHistory = '/salary-history';
  static const String salaryPayment = '/salary-payment';
  static const String salaryAdjustment = '/salary-adjustment';
  static const String salarySlip = '/salary-slip';

  // Barcode
  static const String barcodeScanner = '/barcode-scanner';
  static const String barcodeHistory = '/barcode-history';

  // Reports
  static const String reports = '/reports';

  // Backup
  static const String backup = '/backup';
  static const String restoreBackup = '/restore-backup';

  // Security
  static const String pinLock = '/pin-lock';
  static const String pinSetup = '/pin-setup';

  // Settings
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes {
    return {
      // Dashboard
      dashboard: (context) => const DashboardScreen(),

      // Expenses
      expenses: (context) => const ExpensesScreen(),

      addExpense: (context) {
        final arguments =
            ModalRoute.of(context)?.settings.arguments;

        return AddExpenseScreen(
          expense: arguments as ExpenseModel?,
        );
      },

      expenseDetails: (context) {
        final arguments =
            ModalRoute.of(context)?.settings.arguments
                as ExpenseModel;

        return ExpenseDetailsScreen(
          expense: arguments,
        );
      },

      // Expense Filter
      expenseFilter: (context) => const ExpenseFilterScreen(),

      // Employees
      employees: (context) => const EmployeesScreen(),

      addEmployee: (context) {
        final arguments =
            ModalRoute.of(context)?.settings.arguments;

        return AddEmployeeScreen(
          employee: arguments as EmployeeModel?,
        );
      },

      employeeDetails: (context) {
        final arguments =
            ModalRoute.of(context)?.settings.arguments
                as EmployeeModel;

        return EmployeeDetailsScreen(
          employee: arguments,
        );
      },

      // Attendance
      attendance: (context) => const AttendanceScreen(),

      attendanceHistory: (context) =>
          const AttendanceHistoryScreen(),

      attendanceCalendar: (context) =>
          const AttendanceCalendarScreen(),

      // Salary
      salary: (context) => const SalaryScreen(),

      salaryPayment: (context) {
        final arguments =
            ModalRoute.of(context)?.settings.arguments
                as SalaryModel;

        return SalaryPaymentScreen(
          salary: arguments,
        );
      },

      salaryHistory: (context) =>
          const SalaryHistoryScreen(),

      salaryAdjustment: (context) =>
          const SalaryAdjustmentScreen(),

      salaryDetails: (context) {
        final arguments =
            ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>;

        final employee =
            arguments['employee'] as EmployeeModel;

        final salary =
            arguments['salary'] as SalaryModel;

        return SalarySlipScreen(
          employee: employee,
          salary: salary,
        );
      },

      salarySlip: (context) {
        final arguments =
            ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>;

        final employee =
            arguments['employee'] as EmployeeModel;

        final salary =
            arguments['salary'] as SalaryModel;

        return SalarySlipScreen(
          employee: employee,
          salary: salary,
        );
      },

      // Barcode
      barcodeScanner: (context) =>
          const BarcodeScannerScreen(),

      barcodeHistory: (context) =>
          const BarcodeHistoryScreen(),

      // Reports
      reports: (context) => const ReportsScreen(),

      // Backup
      backup: (context) => const BackupScreen(),

      restoreBackup: (context) =>
          const RestoreBackupScreen(),

      // Security
      pinLock: (context) => const PinLockScreen(),

      pinSetup: (context) => const PinSetupScreen(),

      // Settings
      settings: (context) => const SettingsScreen(),
    };
  }
}
