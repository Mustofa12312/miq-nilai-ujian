class AssignmentModel {
  final int id;
  final String examinerId;
  final int periodId;
  final String periodName;
  final int levelId;
  final String levelName;
  final int classId;
  final String className;
  final int totalStudents;
  final int scoredStudents;

  const AssignmentModel({
    required this.id,
    required this.examinerId,
    required this.periodId,
    required this.periodName,
    required this.levelId,
    required this.levelName,
    required this.classId,
    required this.className,
    required this.totalStudents,
    required this.scoredStudents,
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
      totalStudents: totalStudents,
      scoredStudents: scoredStudents ?? this.scoredStudents,
    );
  }
}
