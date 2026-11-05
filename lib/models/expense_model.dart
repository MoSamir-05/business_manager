class ExpenseModel {
  final int? id;
  final String title;
  final String category;
  final double amount;
  final String description;
  final String expenseDate;
  final String paymentMethod;
  final String? receiptPath;
  final String createdAt;
  final String? updatedAt;
  final String? deletedAt;

  const ExpenseModel({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.description,
    required this.expenseDate,
    required this.paymentMethod,
    this.receiptPath,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  // Database Map se Expense Object
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      expenseDate: map['expense_date'] as String,
      paymentMethod: map['payment_method'] as String,
      receiptPath: map['receipt_path'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  // Expense Object se Database Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate,
      'payment_method': paymentMethod,
      'receipt_path': receiptPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  // Expense Deleted hai ya nahi
  bool get isDeleted => deletedAt != null;

  // Existing Expense Update
  ExpenseModel copyWith({
    int? id,
    String? title,
    String? category,
    double? amount,
    String? description,
    String? expenseDate,
    String? paymentMethod,
    String? receiptPath,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}