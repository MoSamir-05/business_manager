
class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'Business Manager';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Smart Offline Business Management';

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // Database
  static const String databaseName = 'business_manager.db';
  static const int databaseVersion = 1;

  // Backup
  static const String backupFolderName = 'BusinessManagerBackup';
  static const String backupFileExtension = '.bmbackup';

  // Employee Status
  static const String employeeActive = 'Active';
  static const String employeeInactive = 'Inactive';

  // Attendance Status
  static const String attendancePresent = 'Present';
  static const String attendanceAbsent = 'Absent';
  static const String attendanceHalfDay = 'Half Day';
  static const String attendancePaidLeave = 'Paid Leave';

  // Salary Status
  static const String salaryPaid = 'Paid';
  static const String salaryPending = 'Pending';
  static const String salaryPartial = 'Partial';

  // Expense Payment Methods
  static const String paymentCash = 'Cash';
  static const String paymentUPI = 'UPI';
  static const String paymentBank = 'Bank';

  // App Preferences
  static const String themeKey = 'app_theme';
  static const String pinSetupKey = 'pin_setup';
  static const String biometricKey = 'biometric_enabled';

  // Validation
  static const int mobileNumberLength = 10;
  static const int pinLength = 6;

  // Date Formats
  static const String dateFormat = 'dd-MM-yyyy';
  static const String monthFormat = 'MMMM yyyy';

  // Backup Settings
  static const int automaticBackupIntervalDays = 1;
}
