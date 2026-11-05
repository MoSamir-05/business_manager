class SalaryAdjustmentModel {
  final int? id;
  final int employeeId;
  final int salaryMonth;
  final int salaryYear;
  final String adjustmentType;
  final double amount;
  final String description;
  final String createdAt;

  const SalaryAdjustmentModel({
    this.id,
    required this.employeeId,
    required this.salaryMonth,
    required this.salaryYear,
    required this.adjustmentType,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  // Adjustment type constants
  static const String bonus = 'Bonus';
  static const String advance = 'Advance';
  static const String deduction = 'Deduction';

  // Database Map se Adjustment Object
  factory SalaryAdjustmentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return SalaryAdjustmentModel(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      salaryMonth: map['salary_month'] as int,
      salaryYear: map['salary_year'] as int,
      adjustmentType: map['adjustment_type'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      createdAt: map['created_at'] as String,
    );
  }

  // Adjustment Object se Database Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'employee_id': employeeId,
      'salary_month': salaryMonth,
      'salary_year': salaryYear,
      'adjustment_type': adjustmentType,
      'amount': amount,
      'description': description,
      'created_at': createdAt,
    };
  }

  bool get isBonus => adjustmentType == bonus;

  bool get isAdvance => adjustmentType == advance;

  bool get isDeduction => adjustmentType == deduction;

  // Existing Adjustment Update
  SalaryAdjustmentModel copyWith({
    int? id,
    int? employeeId,
    int? salaryMonth,
    int? salaryYear,
    String? adjustmentType,
    double? amount,
    String? description,
    String? createdAt,
  }) {
    return SalaryAdjustmentModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      salaryMonth: salaryMonth ?? this.salaryMonth,
      salaryYear: salaryYear ?? this.salaryYear,
      adjustmentType: adjustmentType ?? this.adjustmentType,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}