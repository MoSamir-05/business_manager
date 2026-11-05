
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/employee_model.dart';
import '../../services/employee_service.dart';
import '../../services/employee_photo_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({
    super.key,
    this.employee,
  });

  final EmployeeModel? employee;

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _salaryController = TextEditingController();

  final EmployeeService _employeeService = EmployeeService.instance;
  final EmployeePhotoService _photoService =
      EmployeePhotoService.instance;

  DateTime _joiningDate = DateTime.now();
  String _status = 'Active';
  String? _photoPath;
  String? _previousPhotoPath;

  bool _isSaving = false;
  bool _isPickingPhoto = false;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();

    final employee = widget.employee;

    if (employee != null) {
      _nameController.text = employee.name;
      _mobileController.text = employee.mobile;
      _addressController.text = employee.address;
      _salaryController.text = employee.basicSalary.toString();

      _joiningDate =
          DateTime.tryParse(employee.joiningDate) ??
          _parseJoiningDate(employee.joiningDate);

      _status = employee.status;
      _photoPath = employee.photoPath;
      _previousPhotoPath = employee.photoPath;
    }
  }

  DateTime _parseJoiningDate(String value) {
    final parts = value.split('-');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }

  Future<void> _showPhotoOptions() async {
    if (_isPickingPhoto || _isSaving) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickPhoto(fromCamera: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickPhoto(fromCamera: false);
                  },
                ),
                if (_photoPath != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() {
                        _photoPath = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    setState(() => _isPickingPhoto = true);

    try {
      final path = fromCamera
          ? await _photoService.takePhoto()
          : await _photoService.selectFromGallery();

      if (!mounted) return;

      if (path != null) {
        setState(() {
          _photoPath = path;
        });
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to select photo. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _pickJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _joiningDate = picked;
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now().toIso8601String();

      final employee = EmployeeModel(
        id: widget.employee?.id,
        photoPath: _photoPath,
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        address: _addressController.text.trim(),
        joiningDate: _formatDate(_joiningDate),
        basicSalary: double.parse(_salaryController.text.trim()),
        status: _status,
        createdAt: widget.employee?.createdAt ?? now,
        updatedAt: now,
        deletedAt: widget.employee?.deletedAt,
      );

      if (_isEditing) {
        await _employeeService.updateEmployee(employee);
      } else {
        await _employeeService.addEmployee(employee);
      }

      if (_previousPhotoPath != null &&
          _previousPhotoPath != _photoPath) {
        await _photoService.deletePhoto(_previousPhotoPath);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Employee updated successfully.'
                : 'Employee added successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save employee. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Employee' : 'Add Employee',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 18),

              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: AppTheme.primary
                                .withValues(alpha: 0.12),
                            backgroundImage: _photoPath != null
                                ? FileImage(File(_photoPath!))
                                : null,
                            child: _photoPath == null
                                ? const Icon(
                                    Icons.person_outline,
                                    size: 55,
                                    color: AppTheme.primary,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.primary,
                              child: const Icon(
                                Icons.camera_alt,
                                size: 19,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed:
                          _isPickingPhoto ? null : _showPhotoOptions,
                      child: Text(
                        _isPickingPhoto
                            ? 'Selecting Photo...'
                            : 'Add Employee Photo (Optional)',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _buildTextField(
                controller: _nameController,
                label: 'Employee Name',
                hint: 'Enter full name',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter employee name.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              _buildTextField(
                controller: _mobileController,
                label: 'Mobile Number',
                hint: 'Enter 10 digit mobile number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.trim().length != 10) {
                    return 'Enter a valid 10 digit mobile number.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              _buildTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'Enter employee address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter employee address.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 26),

              _buildSectionTitle('Employment Information'),
              const SizedBox(height: 18),

              _buildDateField(),

              const SizedBox(height: 18),

              _buildTextField(
                controller: _salaryController,
                label: 'Basic Monthly Salary',
                hint: 'Enter basic salary',
                icon: Icons.currency_rupee_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter basic salary.';
                  }

                  final salary = double.tryParse(value.trim());

                  if (salary == null || salary <= 0) {
                    return 'Enter a valid salary amount.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              _buildStatusField(),

              const SizedBox(height: 30),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSaving || _isPickingPhoto
                      ? null
                      : _saveEmployee,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isEditing ? 'Update Employee' : 'Save Employee',
                    style: const TextStyle(
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickJoiningDate,
      borderRadius: BorderRadius.circular(15),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Joining Date',
          prefixIcon: Icon(Icons.calendar_month_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(15),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(_joiningDate),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.edit_calendar_rounded,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusField() {
    return DropdownButtonFormField<String>(
      initialValue: _status,
      decoration: const InputDecoration(
        labelText: 'Employee Status',
        prefixIcon: Icon(Icons.work_outline_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'Active',
          child: Text('Active'),
        ),
        DropdownMenuItem(
          value: 'Inactive',
          child: Text('Inactive'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _status = value;
          });
        }
      },
    );
  }
}
