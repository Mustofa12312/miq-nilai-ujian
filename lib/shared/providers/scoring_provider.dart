import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/criteria_model.dart';
import '../../core/constants/app_constants.dart';

/// State satu baris kriteria (mistakes count)
class CriteriaEntry {
  final CriteriaModel criteria;
  final int mistakes;

  const CriteriaEntry({required this.criteria, required this.mistakes});

  double get score => criteria.scoreForMistakes(mistakes);

  CriteriaEntry copyWith({int? mistakes}) {
    return CriteriaEntry(
      criteria: criteria,
      mistakes: mistakes ?? this.mistakes,
    );
  }
}

/// State form penilaian lengkap
class ScoringState {
  final List<CriteriaEntry> entries;
  final bool isSaving;
  final bool isSaved;
  final String? error;

  const ScoringState({
    this.entries = const [],
    this.isSaving = false,
    this.isSaved = false,
    this.error,
  });

  double get totalScore =>
      entries.fold(0, (sum, e) => sum + e.score);

  String get grade => AppConstants.calculateGrade(totalScore);

  double get percentage => AppConstants.calculatePercentage(totalScore);

  List<CriteriaEntry> get tajwidEntries =>
      entries.where((e) => e.criteria.category == AppConstants.categoryTajwid).toList();

  List<CriteriaEntry> get fasohahEntries =>
      entries.where((e) => e.criteria.category == AppConstants.categoryFasohah).toList();

  ScoringState copyWith({
    List<CriteriaEntry>? entries,
    bool? isSaving,
    bool? isSaved,
    String? error,
    bool clearError = false,
  }) {
    return ScoringState(
      entries: entries ?? this.entries,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ScoringNotifier extends StateNotifier<ScoringState> {
  ScoringNotifier() : super(const ScoringState());

  void initForStudent() {
    final entries = AppConstants.allCriteria
        .map((c) => CriteriaEntry(criteria: c, mistakes: 0))
        .toList();
    state = ScoringState(entries: entries);
  }

  void incrementMistakes(int criteriaId) {
    state = state.copyWith(
      entries: state.entries.map((e) {
        if (e.criteria.id == criteriaId) {
          if (e.mistakes < e.criteria.maxMistakes) {
            return e.copyWith(mistakes: e.mistakes + 1);
          }
        }
        return e;
      }).toList(),
    );
  }

  void decrementMistakes(int criteriaId) {
    state = state.copyWith(
      entries: state.entries.map((e) {
        if (e.criteria.id == criteriaId && e.mistakes > 0) {
          return e.copyWith(mistakes: e.mistakes - 1);
        }
        return e;
      }).toList(),
    );
  }

  Future<bool> saveScore(int studentId) async {
    state = state.copyWith(isSaving: true, clearError: true);

    // Simulate network save
    await Future.delayed(const Duration(milliseconds: 1000));

    state = state.copyWith(isSaving: false, isSaved: true);
    return true;
  }

  void reset() {
    state = const ScoringState();
  }
}

final scoringProvider =
    StateNotifierProvider<ScoringNotifier, ScoringState>((ref) {
  return ScoringNotifier();
});
