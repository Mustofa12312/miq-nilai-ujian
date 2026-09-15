class CriteriaModel {
  final int id;
  final String category;
  final String name;
  final double defaultScore;
  final double deduction;
  final int sortOrder;

  const CriteriaModel({
    required this.id,
    required this.category,
    required this.name,
    required this.defaultScore,
    required this.deduction,
    required this.sortOrder,
  });

  double scoreForMistakes(int mistakes) {
    final result = defaultScore - (mistakes * deduction);
    return result < 0 ? 0 : result;
  }

  int get maxMistakes => (defaultScore / deduction).floor();
}
