import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/criteria_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/supabase_service.dart';

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
  final bool isLoadingCriteria;
  final String? error;
  // Context yang dibutuhkan saat simpan ke Supabase
  final int? periodId;
  final int? examTypeId;

  const ScoringState({
    this.entries = const [],
    this.isSaving = false,
    this.isSaved = false,
    this.isLoadingCriteria = false,
    this.error,
    this.periodId,
    this.examTypeId,
  });

  double get totalScore =>
      entries.fold(0, (sum, e) => sum + e.score);

  double get maxPossibleScore =>
      entries.fold(0, (sum, e) => sum + e.criteria.defaultScore);

  String get grade => AppConstants.calculateGrade(totalScore, maxPossibleScore);

  double get percentage => maxPossibleScore > 0
      ? (totalScore / maxPossibleScore) * 100
      : 0;

  List<CriteriaEntry> get tajwidEntries =>
      entries.where((e) => e.criteria.category == AppConstants.categoryTajwid).toList();

  List<CriteriaEntry> get fasohahEntries =>
      entries.where((e) => e.criteria.category == AppConstants.categoryFasohah).toList();

  ScoringState copyWith({
    List<CriteriaEntry>? entries,
    bool? isSaving,
    bool? isSaved,
    bool? isLoadingCriteria,
    String? error,
    bool clearError = false,
    int? periodId,
    int? examTypeId,
  }) {
    return ScoringState(
      entries: entries ?? this.entries,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      isLoadingCriteria: isLoadingCriteria ?? this.isLoadingCriteria,
      error: clearError ? null : (error ?? this.error),
      periodId: periodId ?? this.periodId,
      examTypeId: examTypeId ?? this.examTypeId,
    );
  }
}

class ScoringNotifier extends StateNotifier<ScoringState> {
  ScoringNotifier() : super(const ScoringState());

  /// Inisialisasi form — muat kriteria dari Supabase, resolve periode & exam_type
  Future<void> initForStudent({int? periodId, int? examTypeId}) async {
    state = state.copyWith(isLoadingCriteria: true, clearError: true);

    try {
      // 1. Muat kriteria dari database (bukan hardcode)
      final criteriaRes = await supabase
          .from('criteria')
          .select('*')
          .eq('active', true)
          .order('sort_order', ascending: true);

      final criteria = (criteriaRes as List)
          .map((json) => CriteriaModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final entries = criteria
          .map((c) => CriteriaEntry(criteria: c, mistakes: 0))
          .toList();

      // 2. Resolve periode aktif jika tidak dikirim dari luar
      int? activePeriodId = periodId;
      if (activePeriodId == null) {
        final periodRes = await supabase
            .from('exam_periods')
            .select('id')
            .eq('active', true)
            .maybeSingle();
        activePeriodId = periodRes != null ? (periodRes['id'] as num).toInt() : null;
      }

      // 3. Resolve exam_type default jika tidak dikirim dari luar
      int? activeExamTypeId = examTypeId;
      if (activeExamTypeId == null) {
        final examTypeRes = await supabase
            .from('exam_types')
            .select('id')
            .order('id', ascending: true)
            .limit(1)
            .maybeSingle();
        activeExamTypeId = examTypeRes != null
            ? (examTypeRes['id'] as num).toInt()
            : null;
      }

      state = state.copyWith(
        entries: entries,
        isLoadingCriteria: false,
        periodId: activePeriodId,
        examTypeId: activeExamTypeId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingCriteria: false,
        error: 'Gagal memuat kriteria: ${e.toString()}',
      );
    }
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

  Future<bool> saveScore(int studentId, int classId) async {
    if (state.periodId == null || state.examTypeId == null) {
      state = state.copyWith(
        error: 'Tidak ada periode atau jenis ujian aktif. Hubungi administrator.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final user = supabaseAuth.currentUser;
      if (user == null) throw Exception('Sesi login tidak valid. Silakan login kembali.');

      // 1. Cek BR-001 — apakah sudah ada nilai untuk santri ini di periode ini?
      final existing = await supabase
          .from('scores')
          .select('id, locked')
          .eq('student_id', studentId)
          .eq('period_id', state.periodId!)
          .eq('exam_type_id', state.examTypeId!)
          .maybeSingle();

      if (existing != null) {
        final isLocked = existing['locked'] as bool? ?? false;
        throw Exception(isLocked
            ? 'Nilai santri ini sudah dikunci dan tidak dapat diubah.'
            : 'Santri ini sudah memiliki nilai untuk periode ujian ini.');
      }

      // 2. Buat score_session
      final sessionRes = await supabase
          .from('score_sessions')
          .insert({
            'examiner_id': user.id,
            'class_id': classId,
            'period_id': state.periodId,
            'exam_type_id': state.examTypeId,
            'finished_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      // 3. Buat score dengan period_id dan exam_type_id (enforcing BR-001)
      final scoreRes = await supabase
          .from('scores')
          .insert({
            'session_id': sessionRes['id'],
            'student_id': studentId,
            'total_score': state.totalScore,
            'grade': state.grade,
            'period_id': state.periodId,
            'exam_type_id': state.examTypeId,
          })
          .select()
          .single();

      // 4. Buat score_details (satu baris per kriteria)
      final details = state.entries.map((e) => {
            'score_id': scoreRes['id'],
            'criteria_id': e.criteria.id,
            'mistakes': e.mistakes,
            'score': e.score,
          }).toList();

      if (details.isNotEmpty) {
        await supabase.from('score_details').insert(details);
      }

      state = state.copyWith(isSaving: false, isSaved: true);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() {
    state = const ScoringState();
  }
}

final scoringProvider =
    StateNotifierProvider<ScoringNotifier, ScoringState>((ref) {
  return ScoringNotifier();
});
