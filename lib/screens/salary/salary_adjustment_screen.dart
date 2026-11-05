
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/employee_model.dart';
import '../../models/salary_adjustment_model.dart';
import '../../services/employee_service.dart';
import '../../services/salary_adjustment_service.dart';

class SalaryAdjustmentScreen extends StatefulWidget {
  const SalaryAdjustmentScreen({super.key});

  @override
  State<SalaryAdjustmentScreen> createState() =>
      _SalaryAdjustmentScreenState();
}

class _SalaryAdjustmentScreenState
    extends State<SalaryAdjustmentScreen> {
  final SalaryAdjustmentService _adjustmentService =
      SalaryAdjustmentService.instance;

  final EmployeeService _employeeService =
      EmployeeService.instance;

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  List<EmployeeModel> _employees = [];
  List<SalaryAdjustmentModel> _adjustments = [];

  EmployeeModel? _selectedEmployee;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  String _selectedType = SalaryAdjustmentModel.bonus;

  bool _isLoading = true;
  bool _isSaving = false;

  double _bonus = 0;
  double _advance = 0;
  double _deduction = 0;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _employeeService.getAllEmployees();

      if (!mounted) return;

      final activeEmployees =
          employees.where((employee) => employee.isActive).toList();

      setState(() {
        _employees = activeEmployees;
        _selectedEmployee =
            activeEmployees.isNotEmpty ? activeEmployees.first : null;
      });

      await _loadAdjustments();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Unable to load employees.');
    }
  }

  Future<void> _loadAdjustments() async {
    if (_selectedEmployee?.id == null) {
      if (mounted) {
        setState(() {
          _adjustments = [];
          _bonus = 0;
          _advance = 0;
          _deduction = 0;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final adjustments =
          await _adjustmentService.getMonthlyAdjustments(
        employeeId: _selectedEmployee!.id!,
        month: _selectedMonth,
        year: _selectedYear,
      );

      final totals =
          await _adjustmentService.getMonthlyAdjustmentTotals(
        employeeId: _selectedEmployee!.id!,
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (!mounted) return;

      setState(() {
        _adjustments = adjustments;
        _bonus = totals['bonus'] ?? 0;
        _advance = totals['advance'] ?? 0;
        _deduction = totals['deduction'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Unable to load salary adjustments.');
    }
  }

  Future<void> _changeMonth(int difference) async {
    var month = _selectedMonth + difference;
    var year = _selectedYear;

    if (month > 12) {
      month = 1;
      year++;
    } else if (month < 1) {
      month = 12;
      year--;
    }

    setState(() {
      _selectedMonth = month;
      _selectedYear = year;
      _isLoading = true;
    });

    await _loadAdjustments();
  }

  Future<void> _addAdjustment() async {
    if (_selectedEmployee?.id == null) {
      _showMessage('Please select an employee.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      _showMessage('Enter a valid amount greater than zero.');
      return;
    }

    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      _showMessage('Please enter a description.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final adjustment = SalaryAdjustmentModel(
        employeeId: _selectedEmployee!.id!,
        salaryMonth: _selectedMonth,
        salaryYear: _selectedYear,
        adjustmentType: _selectedType,
        amount: amount,
        description: description,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _adjustmentService.addAdjustment(adjustment);

      if (!mounted) return;

      _amountController.clear();
      _descriptionController.clear();

      setState(() => _isSaving = false);

      Navigator.pop(context);

      _showMessage('Salary adjustment added successfully.');

      await _loadAdjustments();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _showAddDialog() async {
    _selectedType = SalaryAdjustmentModel.bonus;
    _amountController.clear();
    _descriptionController.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add Salary Adjustment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Adjustment Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: SalaryAdjustmentModel.bonus,
                          child: Text('Bonus'),
                        ),
                        DropdownMenuItem(
                          value: SalaryAdjustmentModel.advance,
                          child: Text('Advance'),
                        ),
                        DropdownMenuItem(
                          value: SalaryAdjustmentModel.deduction,
                          child: Text('Other Deduction'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          _selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter reason or details',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _addAdjustment,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Save Adjustment'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAdjustment(
    SalaryAdjustmentModel adjustment,
  ) async {
    if (adjustment.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Adjustment?'),
        content: const Text(
          'Are you sure you want to delete this adjustment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adjustmentService.deleteAdjustment(adjustment.id!);
      await _loadAdjustments();

      if (!mounted) return;

      _showMessage('Adjustment deleted successfully.');
    } catch (e) {
      _showMessage('Unable to delete adjustment.');
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

  Widget _summaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '₹${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    if (type == SalaryAdjustmentModel.bonus) {
      return AppTheme.success;
    }

    if (type == SalaryAdjustmentModel.advance) {
      return AppTheme.warning;
    }

    return AppTheme.danger;
  }

  IconData _typeIcon(String type) {
    if (type == SalaryAdjustmentModel.bonus) {
      return Icons.card_giftcard;
    }

    if (type == SalaryAdjustmentModel.advance) {
      return Icons.payments_outlined;
    }

    return Icons.remove_circle_outline;
  }

  String _typeName(String type) {
    if (type == SalaryAdjustmentModel.bonus) return 'Bonus';
    if (type == SalaryAdjustmentModel.advance) return 'Advance';
    return 'Other Deduction';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Salary Adjustments'),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _employees.isEmpty ? null : _showAddDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Adjustment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 55,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No active employees found.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add an employee before managing salary adjustments.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
                    children: [
                      DropdownButtonFormField<EmployeeModel>(
                        initialValue: _selectedEmployee,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Employee',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: _employees.map((employee) {
                          return DropdownMenuItem(
                            value: employee,
                            child: Text(
                              employee.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (employee) async {
                          if (employee == null) return;

                          setState(() {
                            _selectedEmployee = employee;
                            _isLoading = true;
                          });

                          await _loadAdjustments();
                        },
                      ),

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => _changeMonth(-1),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Expanded(
                              child: Text(
                                DateFormat('MMMM yyyy').format(
                                  DateTime(_selectedYear, _selectedMonth),
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _changeMonth(1),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          _summaryCard(
                            'Bonus',
                            _bonus,
                            Icons.card_giftcard,
                            AppTheme.success,
                          ),
                          const SizedBox(width: 10),
                          _summaryCard(
                            'Advance',
                            _advance,
                            Icons.payments_outlined,
                            AppTheme.warning,
                          ),
                          const SizedBox(width: 10),
                          _summaryCard(
                            'Deduction',
                            _deduction,
                            Icons.remove_circle_outline,
                            AppTheme.danger,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Adjustment History',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 12),

                      if (_adjustments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 42,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'No adjustments for this month.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Tap Add Adjustment to create one.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._adjustments.map((adjustment) {
                          final color =
                              _typeColor(adjustment.adjustmentType);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    _typeIcon(adjustment.adjustmentType),
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _typeName(
                                          adjustment.adjustmentType,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        adjustment.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${adjustment.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          _deleteAdjustment(adjustment),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: 20),

                      Text(
                        'Important: After adding or deleting an adjustment, '
                        'regenerate the employee salary for this month '
                        'to apply the changes to the salary record.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
