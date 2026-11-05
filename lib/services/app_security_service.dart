import 'pin_service.dart';

class AppSecurityService {
  AppSecurityService._();

  static final AppSecurityService instance =
      AppSecurityService._();

  final PinService _pinService = PinService.instance;

  // Check whether owner has enabled PIN
  Future<bool> isPinSecurityEnabled() async {
    return await _pinService.isPinSetup();
  }

  // Enable PIN security
  Future<void> enablePinSecurity(String pin) async {
    await _pinService.setupPin(pin);
  }

  // Disable PIN security
  Future<void> disablePinSecurity(String currentPin) async {
    await _pinService.removePin(currentPin);
  }

  // Check whether app needs PIN lock
  Future<bool> shouldLockApp() async {
    return await isPinSecurityEnabled();
  }

  // Verify owner PIN
  Future<bool> verifyOwnerPin(String pin) async {
    return await _pinService.verifyPin(pin);
  }

  // Change owner PIN
  Future<void> changeOwnerPin({
    required String currentPin,
    required String newPin,
  }) async {
    await _pinService.changePin(
      currentPin: currentPin,
      newPin: newPin,
    );
  }
}