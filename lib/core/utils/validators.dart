
class AppValidators {
  AppValidators._();

  // Required field validation.
  static String? requiredField(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  // Employee name validation.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must contain at least 2 characters';
    }

    if (value.trim().length > 60) {
      return 'Name cannot exceed 60 characters';
    }

    return null;
  }

  // Indian mobile number validation.
  static String? mobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }

    final number = value.trim();

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(number)) {
      return 'Enter a valid 10-digit mobile number';
    }

    return null;
  }

  // Amount validation.
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final parsedAmount = double.tryParse(value.trim());

    if (parsedAmount == null) {
      return 'Enter a valid amount';
    }

    if (!parsedAmount.isFinite || parsedAmount <= 0) {
      return 'Amount must be greater than zero';
    }

    return null;
  }

  // Salary validation.
  static String? salary(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Basic salary is required';
    }

    final parsedSalary = double.tryParse(value.trim());

    if (parsedSalary == null) {
      return 'Enter a valid salary';
    }

    if (!parsedSalary.isFinite || parsedSalary < 0) {
      return 'Salary cannot be negative';
    }

    return null;
  }

  // PIN validation.
  static String? pin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'PIN must contain exactly 6 digits';
    }

    return null;
  }

  // Confirm PIN validation.
  static String? confirmPin(
    String? value,
    String originalPin,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your PIN';
    }

    if (value != originalPin) {
      return 'PIN does not match';
    }

    return null;
  }

  // Barcode validation.
  static String? barcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Barcode number is required';
    }

    if (value.trim().length > 100) {
      return 'Barcode number is too long';
    }

    return null;
  }

  // Description validation.
  static String? description(String? value) {
    if (value != null && value.length > 500) {
      return 'Description cannot exceed 500 characters';
    }

    return null;
  }
}
