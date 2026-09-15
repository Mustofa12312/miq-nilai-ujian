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
}
