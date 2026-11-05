import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';

class PinService {
  PinService._();

  static final PinService instance = PinService._();

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _pinHashKey = 'owner_pin_hash';
  static const String _pinSaltKey = 'owner_pin_salt';

  // Check whether owner PIN is already configured
  Future<bool> isPinSetup() async {
    final hash = await _storage.read(key: _pinHashKey);
    final salt = await _storage.read(key: _pinSaltKey);

    return hash != null && salt != null;
  }

  // Set a new owner PIN
  Future<void> setupPin(String pin) async {
    _validatePin(pin);

    final salt = _generateSalt();
    final hash = _generateHash(pin, salt);

    await _storage.write(
      key: _pinSaltKey,
      value: salt,
    );

    await _storage.write(
      key: _pinHashKey,
      value: hash,
    );
  }

  // Verify owner PIN
  Future<bool> verifyPin(String enteredPin) async {
    if (!_isValidPinFormat(enteredPin)) {
      return false;
    }

    final savedHash = await _storage.read(
      key: _pinHashKey,
    );

    final salt = await _storage.read(
      key: _pinSaltKey,
    );

    if (savedHash == null || salt == null) {
      return false;
    }

    final enteredHash = _generateHash(
      enteredPin,
      salt,
    );

    return _constantTimeEquals(
      savedHash,
      enteredHash,
    );
  }

  // Change existing owner PIN
  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final isCorrect = await verifyPin(currentPin);

    if (!isCorrect) {
      throw Exception('Current PIN is incorrect.');
    }

    _validatePin(newPin);

    final salt = _generateSalt();
    final hash = _generateHash(newPin, salt);

    await _storage.write(
      key: _pinSaltKey,
      value: salt,
    );

    await _storage.write(
      key: _pinHashKey,
      value: hash,
    );
  }

  // Remove owner PIN
  Future<void> removePin(String currentPin) async {
    final isCorrect = await verifyPin(currentPin);

    if (!isCorrect) {
      throw Exception('Current PIN is incorrect.');
    }

    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
  }

  // Validate PIN
  void _validatePin(String pin) {
    if (!_isValidPinFormat(pin)) {
      throw ArgumentError(
        'PIN must contain exactly ${AppConstants.pinLength} digits.',
      );
    }
  }

  bool _isValidPinFormat(String pin) {
    final pattern = RegExp(
      '^\\d{${AppConstants.pinLength}}\$',
    );

    return pattern.hasMatch(pin);
  }

  // Generate a secure random salt
  String _generateSalt() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );

    return base64UrlEncode(bytes);
  }

  // Generate SHA-256 hash
  String _generateHash(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');

    return sha256.convert(bytes).toString();
  }

  // Constant-time string comparison
  bool _constantTimeEquals(String first, String second) {
    if (first.length != second.length) {
      return false;
    }

    int difference = 0;

    for (int i = 0; i < first.length; i++) {
      difference |= first.codeUnitAt(i) ^ second.codeUnitAt(i);
    }

    return difference == 0;
  }
}