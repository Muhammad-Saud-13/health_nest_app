class User {
  final int id;
  final String employeeCode;
  final String name;
  final String email;
  final String role; // HR, EMPLOYEE
  final int? departmentId;
  final int? plantId;
  final String? designation;
  final bool isActive;

  const User({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.role,
    this.departmentId,
    this.plantId,
    this.designation,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      employeeCode: json['employee_code'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'EMPLOYEE',
      departmentId: json['department_id'] as int?,
      plantId: json['plant_id'] as int?,
      designation: json['designation'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'name': name,
      'email': email,
      'role': role,
      'department_id': departmentId,
      'plant_id': plantId,
      'designation': designation,
      'is_active': isActive ? 1 : 0,
    };
  }

  User copyWith({
    int? id,
    String? employeeCode,
    String? name,
    String? email,
    String? role,
    int? departmentId,
    int? plantId,
    String? designation,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      departmentId: departmentId ?? this.departmentId,
      plantId: plantId ?? this.plantId,
      designation: designation ?? this.designation,
      isActive: isActive ?? this.isActive,
    );
  }
}
