import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Save any setting
  Future<void> saveSetting({
    required String key,
    required String value,
  }) async {
    final db = await _databaseHelper.database;

    await db.insert(
      'app_settings',
      {
        'setting_key': key,
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get any setting
  Future<String?> getSetting(String key) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first['setting_value'] as String?;
  }

  // Get all settings
  Future<Map<String, String>> getAllSettings() async {
    final db = await _databaseHelper.database;

    final result = await db.query('app_settings');

    final Map<String, String> settings = {};

    for (final row in result) {
      settings[row['setting_key'] as String] =
          row['setting_value'] as String;
    }

    return settings;
  }

  // Save theme preference
  Future<void> saveTheme(String theme) async {
    if (theme != 'light' && theme != 'dark' && theme != 'system') {
      throw ArgumentError('Invalid theme selection.');
    }

    await saveSetting(
      key: AppConstants.themeKey,
      value: theme,
    );
  }

  // Get saved theme
  Future<String> getTheme() async {
    return await getSetting(AppConstants.themeKey) ?? 'light';
  }

  // Save date format
  Future<void> saveDateFormat(String format) async {
    const allowedFormats = [
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'MM-dd-yyyy',
    ];

    if (!allowedFormats.contains(format)) {
      throw ArgumentError('Invalid date format.');
    }

    await saveSetting(
      key: 'date_format',
      value: format,
    );
  }

  // Get date format
  Future<String> getDateFormat() async {
    return await getSetting('date_format') ??
        AppConstants.dateFormat;
  }

  // Save monthly non-working dates
  Future<void> saveNonWorkingDates({
    required int month,
    required int year,
    required List<DateTime> dates,
  }) async {
    if (month < 1 || month > 12) {
      throw ArgumentError('Invalid month.');
    }

    final daysInMonth = DateTime(year, month + 1, 0).day;

    final formattedDates = <String>{};

    for (final date in dates) {
      if (date.year != year ||
          date.month != month ||
          date.day > daysInMonth) {
        throw ArgumentError(
          'All non-working dates must belong to the selected month.',
        );
      }

      formattedDates.add(_formatDate(date));
    }

    final key =
        'non_working_dates_${year}_${month.toString().padLeft(2, '0')}';

    final value = jsonEncode(formattedDates.toList()..sort());

    await saveSetting(
      key: key,
      value: value,
    );
  }

  // Get monthly non-working dates
  Future<List<DateTime>> getNonWorkingDates({
    required int month,
    required int year,
  }) async {
    final key =
        'non_working_dates_${year}_${month.toString().padLeft(2, '0')}';

    final value = await getSetting(key);

    if (value == null || value.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        throw const FormatException('Invalid date list.');
      }

      return decoded
          .whereType<String>()
          .map((date) => DateTime.parse(date))
          .where((date) =>
              date.year == year && date.month == month)
          .toList();
    } catch (_) {
      throw const FormatException(
        'Saved non-working dates could not be read.',
      );
    }
  }

  // Save currency preference
  Future<void> saveCurrency({
    required String symbol,
    required String code,
  }) async {
    if (symbol.trim().isEmpty || code.trim().isEmpty) {
      throw ArgumentError('Currency information is required.');
    }

    await saveSetting(
      key: 'currency_symbol',
      value: symbol.trim(),
    );

    await saveSetting(
      key: 'currency_code',
      value: code.trim().toUpperCase(),
    );
  }

  // Get currency symbol
  Future<String> getCurrencySymbol() async {
    return await getSetting('currency_symbol') ??
        AppConstants.currencySymbol;
  }

  // Get currency code
  Future<String> getCurrencyCode() async {
    return await getSetting('currency_code') ??
        AppConstants.currencyCode;
  }

  // Delete a setting
  Future<int> deleteSetting(String key) async {
    final db = await _databaseHelper.database;

    return await db.delete(
      'app_settings',
      where: 'setting_key = ?',
      whereArgs: [key],
    );
  }

  // Format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}