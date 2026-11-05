class EmployeeModel {
  final int? id;
  final String? photoPath;
  final String name;
  final String mobile;
  final String address;
  final String joiningDate;
  final double basicSalary;
  final String status;
  final String createdAt;
  final String? updatedAt;
  final String? deletedAt;

  const EmployeeModel({
    this.id,
    this.photoPath,
    required this.name,
    required this.mobile,
    required this.address,
    required this.joiningDate,
    required this.basicSalary,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  // Database Map se Employee Object
  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as int?,
      photoPath: map['photo_path'] as String?,
      name: map['name'] as String,
      mobile: map['mobile'] as String,
      address: map['address'] as String,
      joiningDate: map['joining_date'] as String,
      basicSalary: (map['basic_salary'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  // Employee Object se Database Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'photo_path': photoPath,
      'name': name,
      'mobile': mobile,
      'address': address,
      'joining_date': joiningDate,
      'basic_salary': basicSalary,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  // Employee Active hai ya Inactive
  bool get isActive => status == 'Active';

  // Employee Deleted hai ya nahi
  bool get isDeleted => deletedAt != null;

  // Existing Employee Data Update
  EmployeeModel copyWith({
    int? id,
    String? photoPath,
    String? name,
    String? mobile,
    String? address,
    String? joiningDate,
    double? basicSalary,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      photoPath: photoPath ?? this.photoPath,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      joiningDate: joiningDate ?? this.joiningDate,
      basicSalary: basicSalary ?? this.basicSalary,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}