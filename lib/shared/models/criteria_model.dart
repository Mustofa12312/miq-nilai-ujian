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

  // Mengembalikan total potongan untuk kriteria ini (bukan sisa skor)
  // Logika baru: total = 100 - semua_potongan (dihitung di ScoringState)
  double deductionForMistakes(int mistakes) {
    return mistakes * deduction;
  }

  factory CriteriaModel.fromJson(Map<String, dynamic> json) {
    return CriteriaModel(
      id: (json['id'] as num).toInt(),
      category: json['category'] as String? ?? '',
      name: json['name'] as String? ?? '',
      defaultScore: (json['default_score'] as num).toDouble(),
      deduction: (json['deduction'] as num).toDouble(),
      sortOrder: (json['sort_order'] as num? ?? 0).toInt(),
    );
  }
}
