class StudentModel {
  final int id;
  final int classId;
  final String fullName;
  final bool active;
  final bool isScored;
  final double? totalScore;
  final String? grade;

  const StudentModel({
    required this.id,
    required this.classId,
    required this.fullName,
    required this.active,
    required this.isScored,
    this.totalScore,
    this.grade,
  });

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, 2).toUpperCase();
  }

  StudentModel copyWith({
    bool? isScored,
    double? totalScore,
    String? grade,
  }) {
    return StudentModel(
      id: id,
      classId: classId,
      fullName: fullName,
      active: active,
      isScored: isScored ?? this.isScored,
      totalScore: totalScore ?? this.totalScore,
      grade: grade ?? this.grade,
    );
  }
}
