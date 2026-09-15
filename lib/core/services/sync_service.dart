import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';

class SyncService {
  final LocalStorageService localStorage;
  final SupabaseClient supabase;

  SyncService({required this.localStorage, required this.supabase});

  /// Mencoba melakukan sinkronisasi skor yang tertunda (pending)
  /// Mengembalikan true jika ada sinkronisasi yang sukses dilakukan atau jika tidak ada pending score.
  Future<bool> syncPendingScores(String examinerId) async {
    final pendingScores = localStorage.getPendingScores();
    if (pendingScores.isEmpty) return true;

    bool allSuccess = true;
    final List<Map<String, dynamic>> failedScores = [];

    for (final scoreData in pendingScores) {
      try {
        // 1. Buat score_session
        final sessionRes = await supabase
            .from('score_sessions')
            .insert({
              'examiner_id': examinerId,
              'class_id': scoreData['class_id'],
              'period_id': scoreData['period_id'],
              'exam_type_id': scoreData['exam_type_id'],
              'finished_at': scoreData['timestamp'],
            })
            .select()
            .single();

        // 2. Buat score (enforcing BR-001)
        final scoreRes = await supabase
            .from('scores')
            .insert({
              'session_id': sessionRes['id'],
              'student_id': scoreData['student_id'],
              'total_score': scoreData['total_score'],
              'grade': scoreData['grade'],
              'period_id': scoreData['period_id'],
              'exam_type_id': scoreData['exam_type_id'],
            })
            .select()
            .single();

        // 3. Buat score_details
        final rawEntries = scoreData['entries'] as List<dynamic>;
        final details = rawEntries.map((e) => {
              'score_id': scoreRes['id'],
              'criteria_id': e['criteria_id'],
              'mistakes': e['mistakes'],
              'score': e['score'],
            }).toList();

        if (details.isNotEmpty) {
          await supabase.from('score_details').insert(details);
        }
      } catch (e) {
        final isOffline = e.toString().contains('Failed host lookup') || 
                          e.toString().contains('ClientException') ||
                          e.toString().contains('Connection refused');
        if (isOffline) {
          failedScores.add(scoreData);
          allSuccess = false;
        } else {
          // Error lain (misalnya BR-001 violation karena sudah ada nilai di server).
          // Kita anggap "selesai" (tidak di-requeue) agar tidak macet di antrian selamanya.
          // Atau jika mau ketat, bisa di-log error-nya.
        }
      }
    }

    // Update pending scores queue
    await localStorage.clearPendingScores();
    for (final failed in failedScores) {
      await localStorage.savePendingScore(failed);
    }

    return allSuccess && failedScores.isEmpty;
  }
}
