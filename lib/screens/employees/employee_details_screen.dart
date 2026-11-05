import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/employee_model.dart';
import '../../services/employee_service.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  const EmployeeDetailsScreen({
    super.key,
    required this.employee,
  });

  final EmployeeModel employee;

  @override
  State<EmployeeDetailsScreen> createState() =>
      _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState
    extends State<EmployeeDetailsScreen> {
  final EmployeeService _employeeService = EmployeeService.instance;

  late EmployeeModel _employee;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
  }

  String _formatJoiningDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed != null) {
      return '${parsed.day.toString().padLeft(2, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.year}';
    }

    return value;
  }

  Future<void> _editEmployee() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.addEmployee,
      arguments: _employee,
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteEmployee() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Employee?'),
          content: Text(
            'Are you sure you want to delete ${_employee.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.danger,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || _employee.id == null) return;

    try {
      await _employeeService.deleteEmployee(_employee.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee deleted successfully.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete employee.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Employee Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _deleteEmployee,
            tooltip: 'Delete Employee',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.danger,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildProfileCard(),
          const SizedBox(height: 22),

          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          _buildDetailRow(
            icon: Icons.person_outline_rounded,
            title: 'Employee Name',
            value: _employee.name,
          ),

          _buildDetailRow(
            icon: Icons.phone_outlined,
            title: 'Mobile Number',
            value: _employee.mobile,
          ),

          _buildDetailRow(
            icon: Icons.location_on_outlined,
            title: 'Address',
            value: _employee.address,
          ),

          const SizedBox(height: 18),

          const Text(
            'Employment Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          _buildDetailRow(
            icon: Icons.calendar_month_outlined,
            title: 'Joining Date',
            value: _formatJoiningDate(_employee.joiningDate),
          ),

          _buildDetailRow(
            icon: Icons.currency_rupee_rounded,
            title: 'Basic Monthly Salary',
            value: '₹${_employee.basicSalary.toStringAsFixed(2)}',
          ),

          _buildStatusRow(),

          const SizedBox(height: 28),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _editEmployee,
              icon: const Icon(Icons.edit_rounded),
              label: const Text(
                'Edit Employee',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _deleteEmployee,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.danger,
              ),
              label: const Text(
                'Delete Employee',
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppTheme.danger,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final photoPath = _employee.photoPath;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 43,
            backgroundColor: Colors.white.withOpacity(0.20),
            backgroundImage: photoPath != null &&
                    photoPath.isNotEmpty &&
                    File(photoPath).existsSync()
                ? FileImage(File(photoPath))
                : null,
            child: photoPath == null ||
                    photoPath.isEmpty ||
                    !File(photoPath).existsSync()
                ? const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 45,
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            _employee.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _employee.mobile,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              _employee.status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primary,
            size: 21,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    final isActive = _employee.status == 'Active';

    return _buildDetailRow(
      icon: Icons.work_outline_rounded,
      title: 'Employee Status',
      value: isActive ? 'Active' : 'Inactive',
    );
  }
}