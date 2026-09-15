import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/assignment_model.dart';
import '../../core/constants/app_constants.dart';

class AssignmentNotifier extends StateNotifier<List<AssignmentModel>> {
  AssignmentNotifier() : super([]);

  Future<void> loadAssignments(String examinerId) async {
    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 800));
    state = AppConstants.mockAssignments;
  }

  void updateScoredCount(int classId) {
    state = state.map((a) {
      if (a.classId == classId) {
        return a.copyWith(scoredStudents: a.scoredStudents + 1);
      }
      return a;
    }).toList();
  }

  AssignmentModel? getByClassId(int classId) {
    try {
      return state.firstWhere((a) => a.classId == classId);
    } catch (_) {
      return null;
    }
  }
}

final assignmentProvider =
    StateNotifierProvider<AssignmentNotifier, List<AssignmentModel>>((ref) {
  return AssignmentNotifier();
});

/// Convenience: total stats across all assignments
final totalStatsProvider = Provider<Map<String, int>>((ref) {
  final assignments = ref.watch(assignmentProvider);
  final total = assignments.fold<int>(0, (s, a) => s + a.totalStudents);
  final scored = assignments.fold<int>(0, (s, a) => s + a.scoredStudents);
  return {
    'total': total,
    'scored': scored,
    'remaining': total - scored,
  };
});
