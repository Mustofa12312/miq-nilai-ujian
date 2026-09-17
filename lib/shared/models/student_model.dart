class StudentModel {
  final int id;
  final int classId;
  final int? rantingId;
  final String? nis;
  final String fullName;
  final String? gender;
  final String? fatherName;
  final String? branchCode;
  final String? branchName;
  final String? birthPlace;
  final String? birthDate;
  final String? room;
  final bool active;
  final bool isScored;
  final double? totalScore;
  final String? grade;
  final int? scoreId;
  final bool isLocked;

  const StudentModel({
    required this.id,
    required this.classId,
    this.rantingId,
    this.nis,
    required this.fullName,
    this.gender,
    this.fatherName,
    this.branchCode,
    this.branchName,
    this.birthPlace,
    this.birthDate,
    this.room,
    required this.active,
    required this.isScored,
    this.totalScore,
    this.grade,
    this.scoreId,
    this.isLocked = false,
  });

  String get initials {
    if (fullName.trim().isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.length >= 2
        ? fullName.substring(0, 2).toUpperCase()
        : fullName.toUpperCase();
  }

  StudentModel copyWith({
    bool? isScored,
    double? totalScore,
    String? grade,
    int? scoreId,
    bool? isLocked,
  }) {
    return StudentModel(
      id: id,
      classId: classId,
      rantingId: rantingId,
      nis: nis,
      fullName: fullName,
      gender: gender,
      fatherName: fatherName,
      branchCode: branchCode,
      branchName: branchName,
      birthPlace: birthPlace,
      birthDate: birthDate,
      room: room,
      active: active,
      isScored: isScored ?? this.isScored,
      totalScore: totalScore ?? this.totalScore,
      grade: grade ?? this.grade,
      scoreId: scoreId ?? this.scoreId,
      isLocked: isLocked ?? this.isLocked,
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
      rantingId: json['ranting_id'] != null ? (json['ranting_id'] as num).toInt() : null,
      nis: json['nis'] as String?,
      fullName: json['full_name'] as String? ?? '',
      gender: json['gender'] as String?,
      fatherName: json['father_name'] as String?,
      branchCode: json['branch_code'] as String?,
      branchName: json['branch_name'] as String?,
      birthPlace: json['birth_place'] as String?,
      birthDate: json['birth_date'] as String?,
      room: json['room'] as String?,
      active: json['active'] as bool? ?? true,
      isScored: isScored,
      totalScore: isScored && scoreData != null
          ? (scoreData['total_score'] as num?)?.toDouble()
          : null,
      grade: isScored && scoreData != null ? scoreData['grade'] as String? : null,
      scoreId: isScored && scoreData != null ? (scoreData['id'] as num?)?.toInt() : null,
      isLocked: isScored && scoreData != null ? (scoreData['locked'] as bool? ?? false) : false,
    );
  }
}
