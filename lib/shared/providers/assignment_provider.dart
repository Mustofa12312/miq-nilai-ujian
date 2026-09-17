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
          .eq('active', true)
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
            ranting_id,
            room,
            gender,
            class:classes(
              id,
              name,
              level_id,
              level:levels(id, name)
            ),
            period:exam_periods(id, name),
            ranting:rantings(id, name)
          ''')
          .eq('examiner_id', examinerId)
          .eq('period_id', periodId);

      if (assignmentsRes.isEmpty) {
        state = [];
        return;
      }

      // 3. Untuk setiap penugasan, hitung jumlah santri dan yang sudah dinilai
      final classIds = assignmentsRes
          .map((a) => (a['class_id'] as num).toInt())
          .toSet()
          .toList();

      // Hitung total santri per kelas (nanti difilter per assignment di dart)
      final studentsRes = await supabase
          .from('students')
          .select('id, class_id, ranting_id, room, gender')
          .inFilter('class_id', classIds)
          .eq('active', true);

      // Hitung yang sudah dinilai di periode + exam_type ini
      final scoredRes = await supabase
          .from('scores')
          .select('student_id, students!inner(class_id, ranting_id, room, gender)')
          .eq('period_id', periodId)
          .eq('exam_type_id', defaultExamTypeId)
          .inFilter('students.class_id', classIds);

      final Map<int, int> totalStudentsPerAssignment = {};
      final Map<int, int> scoredPerAssignment = {};

      for (final a in assignmentsRes) {
        final aId = (a['id'] as num).toInt();
        final cId = (a['class_id'] as num).toInt();
        final rId = a['ranting_id'] != null ? (a['ranting_id'] as num).toInt() : null;
        final room = a['room'] as String?;
        final gender = a['gender'] as String?;

        // Hitung total
        int total = 0;
        for (final s in studentsRes) {
          final sCId = (s['class_id'] as num).toInt();
          final sRId = s['ranting_id'] != null ? (s['ranting_id'] as num).toInt() : null;
          final sRoom = s['room'] as String?;
          final sGender = s['gender'] as String?;

          bool matchClass = sCId == cId;
          bool matchRanting = rId == null || sRId == rId;
          bool matchRoom = room == null || room.isEmpty || sRoom == room;
          bool matchGender = gender == null || gender.isEmpty || sGender?.toUpperCase() == gender.toUpperCase();

          if (matchClass && matchRanting && matchRoom && matchGender) total++;
        }
        totalStudentsPerAssignment[aId] = total;

        // Hitung scored
        int scored = 0;
        for (final sc in scoredRes) {
          final studentData = sc['students'] as Map<String, dynamic>? ?? {};
          final sCId = (studentData['class_id'] as num? ?? 0).toInt();
          final sRId = studentData['ranting_id'] != null ? (studentData['ranting_id'] as num).toInt() : null;
          final sRoom = studentData['room'] as String?;
          final sGender = studentData['gender'] as String?;

          bool matchClass = sCId == cId;
          bool matchRanting = rId == null || sRId == rId;
          bool matchRoom = room == null || room.isEmpty || sRoom == room;
          bool matchGender = gender == null || gender.isEmpty || sGender?.toUpperCase() == gender.toUpperCase();

          if (matchClass && matchRanting && matchRoom && matchGender) scored++;
        }
        scoredPerAssignment[aId] = scored;
      }

      // 4. Bangun list AssignmentModel
      final newList = assignmentsRes.map((json) {
        final aId = (json['id'] as num).toInt();
        return AssignmentModel.fromJson(
          json,
          totalStudents: totalStudentsPerAssignment[aId] ?? 0,
          scoredStudents: scoredPerAssignment[aId] ?? 0,
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
          'ranting_id': a.rantingId,
          'ranting': a.rantingId != null ? {'id': a.rantingId, 'name': a.rantingName} : null,
          'room': a.room,
          'gender': a.gender,
          'totalStudents': a.totalStudents,
          'scoredStudents': a.scoredStudents,
          'examTypeId': a.examTypeId,
        }).toList();
        localStorage!.saveAssignments(dataToCache);
      }
    } catch (e, stack) {
      print('ERROR IN loadAssignments: $e');
      print(stack);
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
  void updateScoredCount(int assignmentId) {
    state = state.map((a) {
      if (a.id == assignmentId) {
        return a.copyWith(scoredStudents: a.scoredStudents + 1);
      }
      return a;
    }).toList();
  }

  AssignmentModel? getById(int assignmentId) {
    try {
      return state.firstWhere((a) => a.id == assignmentId);
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
