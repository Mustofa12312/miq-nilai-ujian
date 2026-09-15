import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/student_model.dart';
import '../../core/constants/app_constants.dart';

/// State untuk daftar santri per kelas
class StudentState {
  final List<StudentModel> students;
  final String searchQuery;
  final bool isLoading;

  const StudentState({
    this.students = const [],
    this.searchQuery = '',
    this.isLoading = false,
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
  }) {
    return StudentState(
      students: students ?? this.students,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class StudentNotifier extends StateNotifier<StudentState> {
  StudentNotifier() : super(const StudentState());

  Future<void> loadStudents(int classId) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));
    final students = AppConstants.mockStudentsForClass(classId);
    state = state.copyWith(students: students, isLoading: false);
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  /// Mark student as scored after saving
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
    // Remove current if it was just scored
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
