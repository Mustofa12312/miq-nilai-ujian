import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/criteria_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/local_storage_service.dart';
import 'local_storage_provider.dart';

/// State satu baris kriteria (mistakes count)
class CriteriaEntry {
  final CriteriaModel criteria;
  final int mistakes;

  const CriteriaEntry({required this.criteria, required this.mistakes});

  // Potongan untuk kriteria ini
  double get deduction => criteria.deductionForMistakes(mistakes);

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
  final int? scoreId;
  final bool isLocked;

  const ScoringState({
    this.entries = const [],
    this.isSaving = false,
    this.isSaved = false,
    this.isLoadingCriteria = false,
    this.error,
    this.periodId,
    this.examTypeId,
    this.scoreId,
    this.isLocked = false,
  });

  // Logika baru: Total = 100 - SUM(semua potongan), minimum 0
  double get totalScore {
    final totalDeduction = entries.fold(0.0, (sum, e) => sum + e.deduction);
    return (100 - totalDeduction).clamp(0, 100);
  }

  double get maxPossibleScore => 100;

  // Grade langsung dari nilai final (bukan persentase terhadap maxPossible)
  String get grade => AppConstants.calculateGrade(totalScore);

  double get percentage => totalScore;

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
    int? scoreId,
    bool? isLocked,
  }) {
    return ScoringState(
      entries: entries ?? this.entries,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      isLoadingCriteria: isLoadingCriteria ?? this.isLoadingCriteria,
      error: clearError ? null : (error ?? this.error),
      periodId: periodId ?? this.periodId,
      examTypeId: examTypeId ?? this.examTypeId,
      scoreId: scoreId ?? this.scoreId,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class ScoringNotifier extends StateNotifier<ScoringState> {
  final LocalStorageService? localStorage;
  ScoringNotifier(this.localStorage) : super(const ScoringState());

  /// Inisialisasi form — muat kriteria dari Supabase, resolve periode & exam_type, dan load existing score jika ada
  Future<void> initForStudent({int? studentId, int? periodId, int? examTypeId, int? scoreId, bool isLocked = false}) async {
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

      List<CriteriaEntry> entries = criteria
          .map((c) => CriteriaEntry(criteria: c, mistakes: 0))
          .toList();

      // Jika ada scoreId, ambil rinciannya dari database
      if (scoreId != null) {
        final detailsRes = await supabase
            .from('score_details')
            .select('criteria_id, mistakes')
            .eq('score_id', scoreId);
        
        final Map<int, int> existingMistakes = {};
        for (var row in detailsRes) {
          existingMistakes[(row['criteria_id'] as num).toInt()] = (row['mistakes'] as num).toInt();
        }

        entries = entries.map((e) {
          final m = existingMistakes[e.criteria.id];
          return m != null ? e.copyWith(mistakes: m) : e;
        }).toList();
      } else if (studentId != null && localStorage != null) {
        // Cek offline pending score
        final pending = localStorage!.getPendingScores();
        final match = pending.where((p) => p['student_id'] == studentId).lastOrNull;
        if (match != null) {
          final savedEntries = match['entries'] as List<dynamic>?;
          if (savedEntries != null) {
            final Map<int, int> existingMistakes = {};
            for (var row in savedEntries) {
               existingMistakes[(row['criteria_id'] as num).toInt()] = (row['mistakes'] as num).toInt();
            }
            entries = entries.map((e) {
              final m = existingMistakes[e.criteria.id];
              return m != null ? e.copyWith(mistakes: m) : e;
            }).toList();
          }
        }
      }

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
            .order('id')
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
        scoreId: scoreId,
        isLocked: isLocked,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingCriteria: false,
        error: 'Gagal memuat kriteria: ${e.toString()}',
      );
    }
  }

  void incrementMistakes(int criteriaId) {
    // Logika baru: tidak ada batas maxMistakes per kriteria
    state = state.copyWith(
      entries: state.entries.map((e) {
        if (e.criteria.id == criteriaId) {
          return e.copyWith(mistakes: e.mistakes + 1);
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

      if (state.isLocked) {
        throw Exception('Nilai santri ini sudah dikunci dan tidak dapat diubah.');
      }

      final existing = await supabase
          .from('scores')
          .select('id, locked')
          .eq('student_id', studentId)
          .eq('period_id', state.periodId!)
          .eq('exam_type_id', state.examTypeId!)
          .maybeSingle();

      if (existing != null && state.scoreId == null) {
        final isLocked = existing['locked'] as bool? ?? false;
        throw Exception(isLocked
            ? 'Nilai santri ini sudah dikunci dan tidak dapat diubah.'
            : 'Santri ini sudah memiliki nilai untuk periode ujian ini. Silakan muat ulang halaman.');
      }

      final actualScoreId = state.scoreId ?? existing?['id'];
      int finalScoreId;

      if (actualScoreId != null) {
        // Mode Update
        final scoreRes = await supabase
            .from('scores')
            .update({
              'period_id': state.periodId, // memicu trigger jika perlu
              'total_score': state.totalScore,
              'grade': state.grade,
            })
            .eq('id', actualScoreId)
            .select()
            .single();
        
        finalScoreId = scoreRes['id'];

        // Hapus detail lama, insert detail baru
        await supabase.from('score_details').delete().eq('score_id', finalScoreId);
      } else {
        // Mode Insert Baru
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

        final scoreRes = await supabase
            .from('scores')
            .insert({
              'session_id': sessionRes['id'],
              'student_id': studentId,
              'period_id': state.periodId,
              'exam_type_id': state.examTypeId,
              'total_score': state.totalScore,
              'grade': state.grade,
            })
            .select()
            .single();
        
        finalScoreId = scoreRes['id'];
      }

      // 4. Buat score_details (satu baris per kriteria)
      // Simpan potongan (bukan sisa skor), trigger DB menghitung ulang total
      final details = state.entries.map((e) => {
            'score_id': finalScoreId,
            'criteria_id': e.criteria.id,
            'mistakes': e.mistakes,
            'score': e.deduction,  // total potongan untuk kriteria ini
          }).toList();

      if (details.isNotEmpty) {
        await supabase.from('score_details').insert(details);
      }

      state = state.copyWith(isSaving: false, isSaved: true);
      return true;
    } catch (e) {
      final isOffline = e.toString().contains('Failed host lookup') || 
                        e.toString().contains('ClientException') ||
                        e.toString().contains('Connection refused');

      if (isOffline && localStorage != null) {
        // Save to offline queue
        await localStorage!.savePendingScore({
          'student_id': studentId,
          'class_id': classId,
          'period_id': state.periodId,
          'exam_type_id': state.examTypeId,
          'total_score': state.totalScore,
          'grade': state.grade,
          'entries': state.entries.map((e) => {
            'criteria_id': e.criteria.id,
            'mistakes': e.mistakes,
            'score': e.deduction,  // simpan potongan
          }).toList(),
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        state = state.copyWith(isSaving: false, isSaved: true);
        return true;
      }

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
  final localStorage = ref.watch(localStorageProvider);
  return ScoringNotifier(localStorage);
});
