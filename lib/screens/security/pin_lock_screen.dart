
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_security_service.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final AppSecurityService _securityService =
      AppSecurityService.instance;

  final TextEditingController _pinController =
      TextEditingController();

  bool _isLoading = false;
  bool _isChecking = true;
  bool _isPinVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    try {
      final isEnabled =
          await _securityService.isPinSecurityEnabled();

      if (!mounted) return;

      if (!isEnabled) {
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _isChecking = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _errorMessage = 'Unable to check PIN security.';
      });
    }
  }

  Future<void> _unlockApp() async {
    final pin = _pinController.text.trim();

    if (pin.length != AppConstants.pinLength) {
      setState(() {
        _errorMessage = 'Enter your 6-digit PIN.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isCorrect =
          await _securityService.verifyOwnerPin(pin);

      if (!mounted) return;

      if (isCorrect) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Incorrect PIN. Please try again.';
          _pinController.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Try again.';
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: _isChecking
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 420,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 44,
                              color: AppTheme.primary,
                            ),
                          ),

                          const SizedBox(height: 28),

                          Text(
                            'Business Manager',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Enter your PIN to unlock the app',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 36),

                          TextField(
                            controller: _pinController,
                            autofocus: true,
                            obscureText: !_isPinVisible,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: AppConstants.pinLength,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(
                                AppConstants.pinLength,
                              ),
                            ],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 12,
                            ),
                            decoration: InputDecoration(
                              hintText: '••••••',
                              counterText: '',
                              filled: true,
                              fillColor: AppTheme.surface,
                              errorText: _errorMessage,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isPinVisible = !_isPinVisible;
                                  });
                                },
                                icon: Icon(
                                  _isPinVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppTheme.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppTheme.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _unlockApp(),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed:
                                  _isLoading ? null : _unlockApp,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Unlock App',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 17,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Your business data is protected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
