
import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  // Format date: 06-11-2026
  static String formatDate(
    DateTime date, {
    String format = 'dd-MM-yyyy',
  }) {
    return DateFormat(format).format(date);
  }

  // Format month: November 2026
  static String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  // Format short month: Nov 2026
  static String formatShortMonth(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  // Format date and time.
  static String formatDateTime(DateTime date) {
    return DateFormat('dd-MM-yyyy hh:mm a').format(date);
  }

  // Convert string into DateTime safely.
  static DateTime? parseDate(
    String? value, {
    String format = 'dd-MM-yyyy',
  }) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      return DateFormat(format).parseStrict(value.trim());
    } catch (_) {
      return DateTime.tryParse(value.trim());
    }
  }

  // Get today's date without time.
  static DateTime today() {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day);
  }

  // Check whether two dates are the same day.
  static bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // Get first date of a month.
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get last date of a month.
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // Get total days in a month.
  static int daysInMonth(DateTime date) {
    return lastDayOfMonth(date).day;
  }

  // Get database-friendly date: yyyy-MM-dd.
  static String databaseDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Get database-friendly month: yyyy-MM.
  static String databaseMonth(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  // Check whether date belongs to current month.
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month;
  }

  // Check whether date belongs to current year.
  static bool isCurrentYear(DateTime date) {
    return date.year == DateTime.now().year;
  }
}
