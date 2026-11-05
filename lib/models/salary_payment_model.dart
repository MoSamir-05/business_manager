class SalaryPaymentModel {
  final int? id;
  final int salaryRecordId;
  final double amount;
  final String paymentDate;
  final String paymentMethod;
  final String? note;
  final String createdAt;

  const SalaryPaymentModel({
    this.id,
    required this.salaryRecordId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.note,
    required this.createdAt,
  });

  // Payment methods
  static const String cash = 'Cash';
  static const String upi = 'UPI';
  static const String bank = 'Bank';

  // Database Map se Payment Object
  factory SalaryPaymentModel.fromMap(Map<String, dynamic> map) {
    return SalaryPaymentModel(
      id: map['id'] as int?,
      salaryRecordId: map['salary_record_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: map['payment_date'] as String,
      paymentMethod: map['payment_method'] as String,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  // Payment Object se Database Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'salary_record_id': salaryRecordId,
      'amount': amount,
      'payment_date': paymentDate,
      'payment_method': paymentMethod,
      'note': note,
      'created_at': createdAt,
    };
  }

  // Existing Payment Update
  SalaryPaymentModel copyWith({
    int? id,
    int? salaryRecordId,
    double? amount,
    String? paymentDate,
    String? paymentMethod,
    String? note,
    String? createdAt,
  }) {
    return SalaryPaymentModel(
      id: id ?? this.id,
      salaryRecordId: salaryRecordId ?? this.salaryRecordId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}