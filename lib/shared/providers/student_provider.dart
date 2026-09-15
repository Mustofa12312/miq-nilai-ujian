import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/student_model.dart';
import '../../core/services/supabase_service.dart';

/// State untuk daftar santri per kelas
class StudentState {
  final List<StudentModel> students;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const StudentState({
    this.students = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  List<StudentModel> get filtered {
    if (searchQuery.isEmpty) return students;
    final q = searchQuery.toLowerCase();
    return students
        .where((s) => s.fullName.toLowerCase().contains(q))
        .toList();
  }

  List<StudentModel> get pending =>
      students.where((s) => !s.isScored).toList();
  List<StudentModel> get scored =>
      students.where((s) => s.isScored).toList();

  int get totalCount => students.length;
  int get scoredCount => scored.length;
  int get pendingCount => pending.length;

  StudentState copyWith({
    List<StudentModel>? students,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return StudentState(
      students: students ?? this.students,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class StudentNotifier extends StateNotifier<StudentState> {
  StudentNotifier() : super(const StudentState());

  /// Muat santri dari Supabase, difilter per periode aktif
  Future<void> loadStudents(int classId, {int? periodId, int? examTypeId}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Ambil daftar santri aktif di kelas ini
      final studentsRes = await supabase
          .from('students')
          .select('id, class_id, full_name, active')
          .eq('class_id', classId)
          .eq('active', true)
          .order('full_name', ascending: true);

      if (studentsRes.isEmpty) {
        state = state.copyWith(students: [], isLoading: false);
        return;
      }

      // 2. Resolve periode aktif dan exam_type jika tidak dikirim dari luar
      int? activePeriodId = periodId;
      int? activeExamTypeId = examTypeId;

      if (activePeriodId == null) {
        final periodRes = await supabase
            .from('exam_periods')
            .select('id')
            .eq('active', true)
            .maybeSingle();
        activePeriodId = periodRes != null ? (periodRes['id'] as num).toInt() : null;
      }

      if (activeExamTypeId == null) {
        final examTypeRes = await supabase
            .from('exam_types')
            .select('id')
            .order('id', ascending: true)
            .limit(1)
            .maybeSingle();
        activeExamTypeId = examTypeRes != null ? (examTypeRes['id'] as num).toInt() : null;
      }

      // 3. Ambil nilai yang sudah ada untuk periode + jenis ujian aktif ini
      final studentIds = studentsRes.map((s) => s['id']).toList();
      Set<int> scoredIds = {};
      Map<int, Map<String, dynamic>> scoreMap = {};

      if (activePeriodId != null && activeExamTypeId != null) {
        final scoresRes = await supabase
            .from('scores')
            .select('student_id, total_score, grade')
            .inFilter('student_id', studentIds)
            .eq('period_id', activePeriodId)
            .eq('exam_type_id', activeExamTypeId);

        for (final sc in scoresRes) {
          final sid = (sc['student_id'] as num).toInt();
          scoredIds.add(sid);
          scoreMap[sid] = sc;
        }
      }

      // 4. Bangun list StudentModel dengan status isScored yang akurat
      final students = studentsRes.map((json) {
        return StudentModel.fromJson(
          json,
          scoredIds: scoredIds,
          scoreMap: scoreMap,
        );
      }).toList();

      state = state.copyWith(students: students, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data santri: ${e.toString()}',
      );
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  /// Mark student as scored secara lokal setelah nilai berhasil disimpan
  void markAsScored(int studentId, double totalScore, String grade) {
    state = state.copyWith(
      students: state.students.map((s) {
        if (s.id == studentId) {
          return s.copyWith(
            isScored: true,
            totalScore: totalScore,
            grade: grade,
          );
        }
        return s;
      }).toList(),
    );
  }

  /// Get next unscored student after current
  StudentModel? getNextPending(int currentStudentId) {
    final pending = state.pending;
    final others = pending.where((s) => s.id != currentStudentId).toList();
    return others.isNotEmpty ? others.first : null;
  }
}

final studentProvider =
    StateNotifierProvider<StudentNotifier, StudentState>((ref) {
  return StudentNotifier();
});

/// Provider for a single student by ID
final studentByIdProvider = Provider.family<StudentModel?, int>((ref, id) {
  final state = ref.watch(studentProvider);
  try {
    return state.students.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});
