
class SalaryModel {
  final int? id;
  final int employeeId;

  final int salaryMonth;
  final int salaryYear;

  final double basicSalary;

  final int totalWorkingDays;
  final double presentDays;
  final double halfDays;
  final int absentDays;
  final int unpaidLeaveDays;

  final double payableDays;
  final double dailyRate;

  final double grossSalary;
  final double bonus;
  final double advanceDeduction;
  final double otherDeduction;

  final double finalPayable;
  final double paidAmount;
  final String status;

  // Salary generation stage
  final String salaryStage;

  final String generatedAt;
  final String? updatedAt;

  const SalaryModel({
    this.id,
    required this.employeeId,
    required this.salaryMonth,
    required this.salaryYear,
    required this.basicSalary,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.halfDays,
    required this.absentDays,
    required this.unpaidLeaveDays,
    required this.payableDays,
    required this.dailyRate,
    required this.grossSalary,
    required this.bonus,
    required this.advanceDeduction,
    required this.otherDeduction,
    required this.finalPayable,
    required this.paidAmount,
    required this.status,
    this.salaryStage = finalStage,
    required this.generatedAt,
    this.updatedAt,
  });

  // Salary status constants
  static const String paid = 'Paid';
  static const String pending = 'Pending';
  static const String partial = 'Partial';

  // Salary generation stage constants
  static const String provisional = 'Provisional';
  static const String finalStage = 'Final';

  // Remaining salary amount
  double get remainingAmount {
    final remaining = finalPayable - paidAmount;
    return remaining > 0 ? remaining : 0;
  }

  // Total deductions
  double get totalDeductions {
    return advanceDeduction + otherDeduction;
  }

  // Payment status checks
  bool get isPaid => status == paid;
  bool get isPending => status == pending;
  bool get isPartial => status == partial;

  // Salary stage checks
  bool get isProvisional => salaryStage == provisional;
  bool get isFinal => salaryStage == finalStage;

  // Database Map se Salary Object
  factory SalaryModel.fromMap(Map<String, dynamic> map) {
    return SalaryModel(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      salaryMonth: map['salary_month'] as int,
      salaryYear: map['salary_year'] as int,
      basicSalary: (map['basic_salary'] as num).toDouble(),
      totalWorkingDays: map['total_working_days'] as int,
      presentDays: (map['present_days'] as num).toDouble(),
      halfDays: (map['half_days'] as num).toDouble(),
      absentDays: map['absent_days'] as int,
      unpaidLeaveDays: map['unpaid_leave_days'] as int,
      payableDays: (map['payable_days'] as num).toDouble(),
      dailyRate: (map['daily_rate'] as num).toDouble(),
      grossSalary: (map['gross_salary'] as num).toDouble(),
      bonus: (map['bonus'] as num).toDouble(),
      advanceDeduction:
          (map['advance_deduction'] as num).toDouble(),
      otherDeduction:
          (map['other_deduction'] as num).toDouble(),
      finalPayable: (map['final_payable'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      status: map['status'] as String,
      salaryStage:
          map['salary_stage'] as String? ?? finalStage,
      generatedAt: map['generated_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  // Salary Object se Database Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'employee_id': employeeId,
      'salary_month': salaryMonth,
      'salary_year': salaryYear,
      'basic_salary': basicSalary,
      'total_working_days': totalWorkingDays,
      'present_days': presentDays,
      'half_days': halfDays,
      'absent_days': absentDays,
      'unpaid_leave_days': unpaidLeaveDays,
      'payable_days': payableDays,
      'daily_rate': dailyRate,
      'gross_salary': grossSalary,
      'bonus': bonus,
      'advance_deduction': advanceDeduction,
      'other_deduction': otherDeduction,
      'final_payable': finalPayable,
      'paid_amount': paidAmount,
      'status': status,
      'salary_stage': salaryStage,
      'generated_at': generatedAt,
      'updated_at': updatedAt,
    };
  }

  // Existing Salary Update
  SalaryModel copyWith({
    int? id,
    int? employeeId,
    int? salaryMonth,
    int? salaryYear,
    double? basicSalary,
    int? totalWorkingDays,
    double? presentDays,
    double? halfDays,
    int? absentDays,
    int? unpaidLeaveDays,
    double? payableDays,
    double? dailyRate,
    double? grossSalary,
    double? bonus,
    double? advanceDeduction,
    double? otherDeduction,
    double? finalPayable,
    double? paidAmount,
    String? status,
    String? salaryStage,
    String? generatedAt,
    String? updatedAt,
  }) {
    return SalaryModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      salaryMonth: salaryMonth ?? this.salaryMonth,
      salaryYear: salaryYear ?? this.salaryYear,
      basicSalary: basicSalary ?? this.basicSalary,
      totalWorkingDays: totalWorkingDays ?? this.totalWorkingDays,
      presentDays: presentDays ?? this.presentDays,
      halfDays: halfDays ?? this.halfDays,
      absentDays: absentDays ?? this.absentDays,
      unpaidLeaveDays: unpaidLeaveDays ?? this.unpaidLeaveDays,
      payableDays: payableDays ?? this.payableDays,
      dailyRate: dailyRate ?? this.dailyRate,
      grossSalary: grossSalary ?? this.grossSalary,
      bonus: bonus ?? this.bonus,
      advanceDeduction: advanceDeduction ?? this.advanceDeduction,
      otherDeduction: otherDeduction ?? this.otherDeduction,
      finalPayable: finalPayable ?? this.finalPayable,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      salaryStage: salaryStage ?? this.salaryStage,
      generatedAt: generatedAt ?? this.generatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
