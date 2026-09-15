class ScoreModel {
  final int id;
  final int studentId;
  final int sessionId;
  final double totalScore;
  final String grade;
  final String? notes;
  final bool locked;
  final DateTime createdAt;
  final List<ScoreDetailModel> details;

  const ScoreModel({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.totalScore,
    required this.grade,
    this.notes,
    required this.locked,
    required this.createdAt,
    required this.details,
  });
}

class ScoreDetailModel {
  final int id;
  final int scoreId;
  final int criteriaId;
  final String criteriaName;
  final String category;
  final int mistakes;
  final double score;

  const ScoreDetailModel({
    required this.id,
    required this.scoreId,
    required this.criteriaId,
    required this.criteriaName,
    required this.category,
    required this.mistakes,
    required this.score,
  });
}
