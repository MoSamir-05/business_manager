import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../services/settings_service.dart';
import '../../services/app_security_service.dart';
import '../security/pin_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService.instance;
  final AppSecurityService _securityService =
      AppSecurityService.instance;

  String _theme = 'light';
  String _dateFormat = 'dd-MM-yyyy';
  String _currencySymbol = '₹';
  String _currencyCode = 'INR';

  DateTime _selectedMonth = DateTime.now();
  List<DateTime> _nonWorkingDates = [];

  bool _pinEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, String>> _currencies = [
    {'name': 'Indian Rupee (INR)', 'symbol': '₹', 'code': 'INR'},
    {'name': 'US Dollar (USD)', 'symbol': '\$', 'code': 'USD'},
    {'name': 'Euro (EUR)', 'symbol': '€', 'code': 'EUR'},
    {'name': 'British Pound (GBP)', 'symbol': '£', 'code': 'GBP'},
  ];

  final List<String> _dateFormats = [
    'dd-MM-yyyy',
    'dd/MM/yyyy',
    'yyyy-MM-dd',
    'MM-dd-yyyy',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final theme = await _settingsService.getTheme();
      final dateFormat = await _settingsService.getDateFormat();
      final symbol = await _settingsService.getCurrencySymbol();
      final code = await _settingsService.getCurrencyCode();
      final pinEnabled =
          await _securityService.isPinSecurityEnabled();

      final dates = await _settingsService.getNonWorkingDates(
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      );

      if (!mounted) return;

      setState(() {
        _theme = theme;
        _dateFormat = dateFormat;
        _currencySymbol = symbol;
        _currencyCode = code;
        _pinEnabled = pinEnabled;
        _nonWorkingDates = dates;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Unable to load some settings.');
    }
  }

  Future<void> _saveTheme(String? value) async {
    if (value == null) return;

    setState(() => _isSaving = true);

    try {
      await AppThemeController.updateTheme(value);

      if (!mounted) return;

      setState(() {
        _theme = value;
        _isSaving = false;
      });

      _showMessage('Theme preference saved.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Unable to save theme.');
    }
  }

  Future<void> _saveDateFormat(String? value) async {
    if (value == null) return;

    setState(() => _isSaving = true);

    try {
      await _settingsService.saveDateFormat(value);

      if (!mounted) return;

      setState(() {
        _dateFormat = value;
        _isSaving = false;
      });

      _showMessage('Date format saved.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Unable to save date format.');
    }
  }

  Future<void> _saveCurrency(Map<String, String>? currency) async {
    if (currency == null) return;

    setState(() => _isSaving = true);

    try {
      await _settingsService.saveCurrency(
        symbol: currency['symbol']!,
        code: currency['code']!,
      );

      if (!mounted) return;

      setState(() {
        _currencySymbol = currency['symbol']!;
        _currencyCode = currency['code']!;
        _isSaving = false;
      });

      _showMessage('Currency preference saved.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Unable to save currency.');
    }
  }

  Future<void> _changeMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select a date in the required month',
    );

    if (selected == null) return;

    final dates = await _settingsService.getNonWorkingDates(
      month: selected.month,
      year: selected.year,
    );

    if (!mounted) return;

    setState(() {
      _selectedMonth = DateTime(selected.year, selected.month);
      _nonWorkingDates = dates;
    });
  }

  Future<void> _addNonWorkingDate() async {
    final firstDay = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );

    final lastDay = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );

    final selected = await showDatePicker(
      context: context,
      initialDate: firstDay,
      firstDate: firstDay,
      lastDate: lastDay,
      helpText: 'Select non-working date',
    );

    if (selected == null) return;

    final alreadyExists = _nonWorkingDates.any(
      (date) =>
          date.year == selected.year &&
          date.month == selected.month &&
          date.day == selected.day,
    );

    if (alreadyExists) {
      _showMessage('This date is already added.');
      return;
    }

    setState(() {
      _nonWorkingDates.add(selected);
      _nonWorkingDates.sort((a, b) => a.compareTo(b));
    });

    await _saveNonWorkingDates();
  }

  Future<void> _removeNonWorkingDate(DateTime date) async {
    setState(() {
      _nonWorkingDates.removeWhere(
        (item) =>
            item.year == date.year &&
            item.month == date.month &&
            item.day == date.day,
      );
    });

    await _saveNonWorkingDates();
  }

  Future<void> _saveNonWorkingDates() async {
    try {
      await _settingsService.saveNonWorkingDates(
        month: _selectedMonth.month,
        year: _selectedMonth.year,
        dates: _nonWorkingDates,
      );

      if (!mounted) return;

      _showMessage('Non-working dates saved.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to save non-working dates.');
    }
  }

  Future<void> _openPinSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PinSetupScreen(),
      ),
    );

    final enabled =
        await _securityService.isPinSecurityEnabled();

    if (!mounted) return;

    setState(() => _pinEnabled = enabled);
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

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      items: items,
      onChanged: _isSaving ? null : onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _sectionTitle(
                    'Appearance',
                    'Customize how your app looks.',
                  ),
                  _settingsCard(
                    child: _buildDropdown<String>(
                      label: 'App Theme',
                      value: _theme,
                      items: const [
                        DropdownMenuItem(
                          value: 'light',
                          child: Text('Light Theme'),
                        ),
                        DropdownMenuItem(
                          value: 'dark',
                          child: Text('Dark Theme'),
                        ),
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('System Default'),
                        ),
                      ],
                      onChanged: _saveTheme,
                    ),
                  ),

                  const SizedBox(height: 26),

                  _sectionTitle(
                    'Regional Preferences',
                    'Set your currency and date format.',
                  ),
                  _settingsCard(
                    child: Column(
                      children: [
                        _buildDropdown<String>(
                          label: 'Date Format',
                          value: _dateFormat,
                          items: _dateFormats.map((format) {
                            return DropdownMenuItem(
                              value: format,
                              child: Text(
                                '${format}  (${DateFormat(format).format(DateTime.now())})',
                              ),
                            );
                          }).toList(),
                          onChanged: _saveDateFormat,
                        ),
                        const SizedBox(height: 18),
                        _buildDropdown<String>(
                          label: 'Currency',
                          value: _currencyCode,
                          items: _currencies.map((currency) {
                            return DropdownMenuItem(
                              value: currency['code']!,
                              child: Text(
                                '${currency['symbol']}  ${currency['name']}',
                              ),
                            );
                          }).toList(),
                          onChanged: (code) {
                            final selected = _currencies.firstWhere(
                              (item) => item['code'] == code,
                            );
                            _saveCurrency(selected);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  _sectionTitle(
                    'Working Days & Holidays',
                    'Choose specific non-working dates for salary calculation.',
                  ),
                  _settingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _changeMonth,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    DateFormat('MMMM yyyy')
                                        .format(_selectedMonth),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.edit_calendar_outlined),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        if (_nonWorkingDates.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No non-working dates added for this month.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          )
                        else
                          ..._nonWorkingDates.map((date) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.event_busy,
                                color: AppTheme.warning,
                              ),
                              title: Text(
                                DateFormat('dd MMM yyyy').format(date),
                              ),
                              subtitle: const Text('Non-working day'),
                              trailing: IconButton(
                                onPressed: () =>
                                    _removeNonWorkingDate(date),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _addNonWorkingDate,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Non-working Date'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'These dates are excluded from actual working days '
                          'when calculating monthly salary.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  _sectionTitle(
                    'Salary Calculation Rules',
                    'Your configured salary calculation method.',
                  ),
                  _settingsCard(
                    child: Column(
                      children: const [
                        _RuleRow(
                          icon: Icons.calculate_outlined,
                          title: 'Calculation Basis',
                          value: 'Actual Working Days',
                        ),
                        Divider(height: 24),
                        _RuleRow(
                          icon: Icons.event_available_outlined,
                          title: 'Weekly Holiday',
                          value: 'No fixed weekly holiday',
                        ),
                        Divider(height: 24),
                        _RuleRow(
                          icon: Icons.timelapse,
                          title: 'Half Day',
                          value: '0.5 day salary',
                        ),
                        Divider(height: 24),
                        _RuleRow(
                          icon: Icons.event_busy_outlined,
                          title: 'Paid Leave',
                          value: 'Unpaid for salary',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  _sectionTitle(
                    'Security',
                    'Protect your business information.',
                  ),
                  _settingsCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.lock_outline,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                      title: const Text(
                        'PIN Security',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _pinEnabled
                            ? 'PIN protection is enabled'
                            : 'Optional PIN protection is disabled',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openPinSettings,
                    ),
                  ),

                  const SizedBox(height: 26),

                  _sectionTitle(
                    'App Information',
                    'Business Manager details.',
                  ),
                  _settingsCard(
                    child: const Column(
                      children: [
                        _RuleRow(
                          icon: Icons.business_center_outlined,
                          title: 'Application',
                          value: 'Business Manager',
                        ),
                        Divider(height: 24),
                        _RuleRow(
                          icon: Icons.storage_outlined,
                          title: 'Storage',
                          value: 'Offline SQLite Database',
                        ),
                        Divider(height: 24),
                        _RuleRow(
                          icon: Icons.cloud_off_outlined,
                          title: 'Internet',
                          value: 'Not Required',
                        ),
                        Divider(height: 24),
                        _RuleRow(
                          icon: Icons.info_outline,
                          title: 'Version',
                          value: '1.0.0',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Business Manager • Offline Business Solution',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _RuleRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}