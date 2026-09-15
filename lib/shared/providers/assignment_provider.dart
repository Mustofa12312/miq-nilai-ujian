import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/assignment_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/local_storage_service.dart';
import 'local_storage_provider.dart';

class AssignmentNotifier extends StateNotifier<List<AssignmentModel>> {
  final LocalStorageService? localStorage;
  AssignmentNotifier(this.localStorage) : super([]);

  Future<void> loadAssignments(String examinerId) async {
    try {
      // 1. Ambil periode aktif dan exam_type default
      final periodRes = await supabase
          .from('exam_periods')
          .select('id, name')
          .eq('active', true)
          .maybeSingle();

      final examTypeRes = await supabase
          .from('exam_types')
          .select('id')
          .order('id', ascending: true)
          .limit(1)
          .maybeSingle();

      if (periodRes == null) {
        state = [];
        return;
      }

      final periodId = (periodRes['id'] as num).toInt();
      final defaultExamTypeId = examTypeRes != null
          ? (examTypeRes['id'] as num).toInt()
          : 1;

      // 2. Ambil penugasan penguji — join dengan kelas, tingkatan, dan periode
      final assignmentsRes = await supabase
          .from('examiner_assignments')
          .select('''
            id,
            examiner_id,
            class_id,
            period_id,
            class:classes(
              id,
              name,
              level_id,
              level:levels(id, name)
            ),
            period:exam_periods(id, name)
          ''')
          .eq('examiner_id', examinerId)
          .eq('period_id', periodId);

      if (assignmentsRes.isEmpty) {
        state = [];
        return;
      }

      // 3. Untuk setiap kelas, hitung jumlah santri dan yang sudah dinilai
      final classIds = assignmentsRes
          .map((a) => (a['class_id'] as num).toInt())
          .toList();

      // Hitung total santri per kelas
      final studentsRes = await supabase
          .from('students')
          .select('class_id')
          .inFilter('class_id', classIds)
          .eq('active', true);

      final Map<int, int> totalStudentsPerClass = {};
      for (final s in studentsRes) {
        final cid = (s['class_id'] as num).toInt();
        totalStudentsPerClass[cid] = (totalStudentsPerClass[cid] ?? 0) + 1;
      }

      // Hitung yang sudah dinilai di periode + exam_type ini
      // Ambil student_id yang ada di scores untuk periode ini
      final scoredRes = await supabase
          .from('scores')
          .select('student_id, students!inner(class_id)')
          .eq('period_id', periodId)
          .eq('exam_type_id', defaultExamTypeId)
          .inFilter('students.class_id', classIds);

      final Map<int, int> scoredPerClass = {};
      for (final sc in scoredRes) {
        final studentData = sc['students'] as Map<String, dynamic>? ?? {};
        final cid = (studentData['class_id'] as num? ?? 0).toInt();
        scoredPerClass[cid] = (scoredPerClass[cid] ?? 0) + 1;
      }

      // 4. Bangun list AssignmentModel
      final newList = assignmentsRes.map((json) {
        final cid = (json['class_id'] as num).toInt();
        return AssignmentModel.fromJson(
          json,
          totalStudents: totalStudentsPerClass[cid] ?? 0,
          scoredStudents: scoredPerClass[cid] ?? 0,
          defaultExamTypeId: defaultExamTypeId,
        );
      }).toList();

      state = newList;

      // 5. Cache ke lokal
      if (localStorage != null) {
        final dataToCache = newList.map((a) => {
          'id': a.id,
          'examiner_id': a.examinerId,
          'period_id': a.periodId,
          'period': {'id': a.periodId, 'name': a.periodName},
          'class_id': a.classId,
          'class': {
            'id': a.classId,
            'name': a.className,
            'level_id': a.levelId,
            'level': {'id': a.levelId, 'name': a.levelName}
          },
          'totalStudents': a.totalStudents,
          'scoredStudents': a.scoredStudents,
          'examTypeId': a.examTypeId,
        }).toList();
        localStorage!.saveAssignments(dataToCache);
      }
    } catch (e) {
      // Jika error (misal offline), coba load dari cache lokal
      if (localStorage != null) {
        final cached = localStorage!.getAssignments();
        if (cached != null) {
          state = cached.map((json) {
            return AssignmentModel.fromJson(
              json,
              totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
              scoredStudents: (json['scoredStudents'] as num?)?.toInt() ?? 0,
              defaultExamTypeId: (json['examTypeId'] as num?)?.toInt() ?? 1,
            );
          }).toList();
          return;
        }
      }
      state = [];
    }
  }

  /// Update jumlah yang sudah dinilai setelah scoring berhasil disimpan
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
  final localStorage = ref.watch(localStorageProvider);
  return AssignmentNotifier(localStorage);
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
