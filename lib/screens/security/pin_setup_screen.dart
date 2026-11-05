
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_security_service.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final AppSecurityService _securityService =
      AppSecurityService.instance;

  final TextEditingController _currentPinController =
      TextEditingController();

  final TextEditingController _newPinController =
      TextEditingController();

  final TextEditingController _confirmPinController =
      TextEditingController();

  bool _isPinEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    try {
      final enabled =
          await _securityService.isPinSecurityEnabled();

      if (!mounted) return;

      setState(() {
        _isPinEnabled = enabled;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load PIN settings.');
    }
  }

  Future<void> _savePin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (_isPinEnabled && currentPin.length != AppConstants.pinLength) {
      _showMessage('Please enter your current PIN.');
      return;
    }

    if (newPin.length != AppConstants.pinLength) {
      _showMessage('New PIN must be 6 digits.');
      return;
    }

    if (confirmPin != newPin) {
      _showMessage('PIN and confirm PIN do not match.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isPinEnabled) {
        await _securityService.changeOwnerPin(
          currentPin: currentPin,
          newPin: newPin,
        );
      } else {
        await _securityService.enablePinSecurity(newPin);
      }

      if (!mounted) return;

      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();

      setState(() {
        _isPinEnabled = true;
        _isSaving = false;
      });

      _showMessage(
        _isPinEnabled
            ? 'PIN security saved successfully.'
            : 'PIN security enabled successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _removePin() async {
    final currentPin = _currentPinController.text.trim();

    if (currentPin.length != AppConstants.pinLength) {
      _showMessage('Please enter your current PIN.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable PIN Security?'),
        content: const Text(
          'Your app will open normally without asking for a PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable PIN'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      await _securityService.disablePinSecurity(currentPin);

      if (!mounted) return;

      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();

      setState(() {
        _isPinEnabled = false;
        _isSaving = false;
      });

      _showMessage('PIN security disabled successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _buildPinField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: AppConstants.pinLength,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(
          AppConstants.pinLength,
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: const Icon(Icons.lock_outline),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('PIN Security'),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Protect Your Business',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set an optional 6-digit PIN to protect '
                            'your Business Manager app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _isPinEnabled
                                  ? AppTheme.success.withOpacity(0.12)
                                  : AppTheme.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _isPinEnabled
                                  ? 'PIN Security Enabled'
                                  : 'PIN Security Disabled',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isPinEnabled
                                    ? AppTheme.success
                                    : AppTheme.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      _isPinEnabled
                          ? 'Change Your PIN'
                          : 'Set Up Your PIN',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),

                    const SizedBox(height: 16),

                    if (_isPinEnabled) ...[
                      _buildPinField(
                        label: 'Current PIN',
                        controller: _currentPinController,
                        hint: 'Enter current 6-digit PIN',
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildPinField(
                      label: 'New PIN',
                      controller: _newPinController,
                      hint: 'Enter new 6-digit PIN',
                    ),

                    const SizedBox(height: 16),

                    _buildPinField(
                      label: 'Confirm PIN',
                      controller: _confirmPinController,
                      hint: 'Re-enter new PIN',
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _savePin,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.lock),
                        label: Text(
                          _isPinEnabled
                              ? 'Update PIN'
                              : 'Enable PIN Security',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    if (_isPinEnabled) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _removePin,
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Disable PIN Security'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            side: BorderSide(
                              color: AppTheme.danger,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    Text(
                      'Note: PIN security is optional. If you do not '
                      'set a PIN, the app will work normally.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}
