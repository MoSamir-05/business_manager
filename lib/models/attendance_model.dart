class AttendanceModel {
  final int? id;
  final int employeeId;
  final String attendanceDate;
  final String status;
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  const AttendanceModel({
    this.id,
    required this.employeeId,
    required this.attendanceDate,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Attendance status constants
  static const String present = 'Present';
  static const String absent = 'Absent';
  static const String halfDay = 'Half Day';
  static const String paidLeave = 'Paid Leave';

  // Database Map se Attendance Object
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      attendanceDate: map['attendance_date'] as String,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  // Attendance Object se Database Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'employee_id': employeeId,
      'attendance_date': attendanceDate,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Attendance status checks
  bool get isPresent => status == present;

  bool get isAbsent => status == absent;

  bool get isHalfDay => status == halfDay;

  bool get isPaidLeave => status == paidLeave;

  // Salary payable day calculation
  double get payableDays {
    switch (status) {
      case present:
        return 1.0;

      case halfDay:
        return 0.5;

      case absent:
      case paidLeave:
      default:
        return 0.0;
    }
  }

  // Existing Attendance Update
  AttendanceModel copyWith({
    int? id,
    int? employeeId,
    String? attendanceDate,
    String? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}