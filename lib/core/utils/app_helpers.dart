
class AppHelpers {
  AppHelpers._();

  // Get initials from a person's name.
  // Example: Mo Samir = MS
  static String getInitials(String name) {
    final cleanedName = name.trim();

    if (cleanedName.isEmpty) {
      return '?';
    }

    final parts = cleanedName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  // Capitalize first letter.
  static String capitalize(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return '';
    }

    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  // Convert text into title case.
  static String titleCase(String value) {
    if (value.trim().isEmpty) {
      return '';
    }

    return value
        .trim()
        .split(RegExp(r'\s+'))
        .map(capitalize)
        .join(' ');
  }

  // Get greeting according to current time.
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    }

    if (hour < 17) {
      return 'Good Afternoon';
    }

    return 'Good Evening';
  }

  // Remove unnecessary spaces.
  static String cleanText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Check whether text is empty.
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  // Get month name.
  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  // Get current year.
  static int getCurrentYear() {
    return DateTime.now().year;
  }
}
