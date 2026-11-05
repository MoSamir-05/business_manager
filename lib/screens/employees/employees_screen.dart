import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/employee_model.dart';
import '../../services/employee_service.dart';
import '../../widgets/employee_list_card.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final EmployeeService _employeeService = EmployeeService.instance;
  final TextEditingController _searchController =
      TextEditingController();

  List<EmployeeModel> _employees = [];

  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employees = await _employeeService.getAllEmployees();

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load employees.');
    }
  }

  List<EmployeeModel> get _filteredEmployees {
    List<EmployeeModel> result = List.from(_employees);

    if (_selectedFilter == 'Active') {
      result = result
          .where((employee) => employee.status == 'Active')
          .toList();
    } else if (_selectedFilter == 'Inactive') {
      result = result
          .where((employee) => employee.status == 'Inactive')
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();

      result = result.where((employee) {
        return employee.name.toLowerCase().contains(query) ||
            employee.mobile.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  int get _activeCount {
    return _employees
        .where((employee) => employee.status == 'Active')
        .length;
  }

  int get _inactiveCount {
    return _employees
        .where((employee) => employee.status == 'Inactive')
        .length;
  }

  void _openAddEmployee() {
    Navigator.pushNamed(
      context,
      AppRoutes.addEmployee,
    ).then((_) {
      if (mounted) {
        _loadEmployees();
      }
    });
  }

  void _openEditEmployee(EmployeeModel employee) {
    Navigator.pushNamed(
      context,
      AppRoutes.addEmployee,
      arguments: employee,
    ).then((_) {
      if (mounted) {
        _loadEmployees();
      }
    });
  }

  void _openEmployeeDetails(EmployeeModel employee) {
    Navigator.pushNamed(
      context,
      AppRoutes.employeeDetails,
      arguments: employee,
    );
  }

  Future<void> _deleteEmployee(EmployeeModel employee) async {
    if (employee.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Employee?'),
          content: Text(
            'Are you sure you want to delete ${employee.name}?',
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

    if (confirmed != true) return;

    try {
      await _employeeService.deleteEmployee(employee.id!);

      if (!mounted) return;

      await _loadEmployees();

      if (!mounted) return;

      _showMessage('Employee deleted successfully.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to delete employee.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Employees',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadEmployees,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddEmployee,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Employee'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryCards(),
            _buildSearchBar(),
            _buildFilters(),
            Expanded(
              child: _buildEmployeeList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              title: 'Total Employees',
              count: _employees.length,
              icon: Icons.groups_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              title: 'Active',
              count: _activeCount,
              icon: Icons.person_outline_rounded,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              title: 'Inactive',
              count: _inactiveCount,
              icon: Icons.person_off_outlined,
              color: AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by name or mobile...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: AppTheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Active', 'Inactive'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final employees = _filteredEmployees;

    if (employees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 60,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 15),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No employees found'
                    : 'No employees yet',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try another name or mobile number.'
                    : 'Add your first employee to get started.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEmployees,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: employees.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final employee = employees[index];

          return EmployeeListCard(
            employee: employee,
            onTap: () => _openEmployeeDetails(employee),
            onEdit: () => _openEditEmployee(employee),
            onDelete: () => _deleteEmployee(employee),
          );
        },
      ),
    );
  }
}