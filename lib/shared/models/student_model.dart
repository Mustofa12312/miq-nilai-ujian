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

  /// Parse dari response Supabase.
  /// [scoredIds] adalah `Set<int>` berisi student_id yang sudah dinilai
  /// pada periode + jenis ujian aktif saat ini.
  factory StudentModel.fromJson(
    Map<String, dynamic> json, {
    Set<int> scoredIds = const {},
    Map<int, Map<String, dynamic>> scoreMap = const {},
  }) {
    final id = (json['id'] as num).toInt();
    final isScored = scoredIds.contains(id);
    final scoreData = scoreMap[id];

    return StudentModel(
      id: id,
      classId: (json['class_id'] as num).toInt(),
      fullName: json['full_name'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      isScored: isScored,
      totalScore: isScored && scoreData != null
          ? (scoreData['total_score'] as num?)?.toDouble()
          : null,
      grade: isScored && scoreData != null ? scoreData['grade'] as String? : null,
    );
  }
}
