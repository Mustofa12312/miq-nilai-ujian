class UserModel {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final bool status;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
  });

  String get firstName => fullName.split(' ').first;

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, 2).toUpperCase();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'examiner'),
      status: json['status'] as bool? ?? true,
    );
  }
}

enum UserRole {
  superAdmin,
  admin,
  examiner,
  leader;

  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin MIQ';
      case UserRole.examiner:
        return 'Penguji';
      case UserRole.leader:
        return 'Pimpinan';
    }
  }

  /// Kolom `role` di database: 'super_admin', 'admin', 'examiner', 'leader'
  static UserRole fromString(String value) {
    switch (value) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'leader':
        return UserRole.leader;
      default:
        return UserRole.examiner;
    }
  }
}
