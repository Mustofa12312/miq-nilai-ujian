class AssignmentModel {
  final int id;
  final String examinerId;
  final int periodId;
  final String periodName;
  final int levelId;
  final String levelName;
  final int classId;
  final String className;
  final int? rantingId;
  final String? rantingName;
  final String? room;
  final String? gender;
  final int totalStudents;
  final int scoredStudents;
  final int examTypeId;

  const AssignmentModel({
    required this.id,
    required this.examinerId,
    required this.periodId,
    required this.periodName,
    required this.levelId,
    required this.levelName,
    required this.classId,
    required this.className,
    this.rantingId,
    this.rantingName,
    this.room,
    this.gender,
    required this.totalStudents,
    required this.scoredStudents,
    this.examTypeId = 1,
  });

  int get remainingStudents => totalStudents - scoredStudents;
  double get progressPercentage =>
      totalStudents > 0 ? scoredStudents / totalStudents : 0.0;
  bool get isComplete => scoredStudents >= totalStudents;

  AssignmentModel copyWith({int? scoredStudents}) {
    return AssignmentModel(
      id: id,
      examinerId: examinerId,
      periodId: periodId,
      periodName: periodName,
      levelId: levelId,
      levelName: levelName,
      classId: classId,
      className: className,
      rantingId: rantingId,
      rantingName: rantingName,
      room: room,
      gender: gender,
      totalStudents: totalStudents,
      scoredStudents: scoredStudents ?? this.scoredStudents,
      examTypeId: examTypeId,
    );
  }

  factory AssignmentModel.fromJson(
    Map<String, dynamic> json, {
    required int totalStudents,
    required int scoredStudents,
    required int defaultExamTypeId,
  }) {
    final classData = json['class'] as Map<String, dynamic>? ?? {};
    final levelData = classData['level'] as Map<String, dynamic>? ?? {};
    final periodData = json['period'] as Map<String, dynamic>? ?? {};
    final rantingData = json['ranting'] as Map<String, dynamic>? ?? {};

    return AssignmentModel(
      id: (json['id'] as num).toInt(),
      examinerId: json['examiner_id'] as String? ?? '',
      periodId: (json['period_id'] as num).toInt(),
      periodName: periodData['name'] as String? ?? '',
      levelId: (classData['level_id'] as num? ?? 0).toInt(),
      levelName: levelData['name'] as String? ?? '',
      classId: (json['class_id'] as num).toInt(),
      className: classData['name'] as String? ?? '',
      rantingId: json['ranting_id'] != null ? (json['ranting_id'] as num).toInt() : null,
      rantingName: rantingData['name'] as String?,
      room: json['room'] as String?,
      gender: json['gender'] as String?,
      totalStudents: totalStudents,
      scoredStudents: scoredStudents,
      examTypeId: defaultExamTypeId,
    );
  }
}
