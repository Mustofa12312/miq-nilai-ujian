import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/local_storage_provider.dart';
import '../../shared/providers/sync_provider.dart';

class SyncQueueScreen extends ConsumerStatefulWidget {
  const SyncQueueScreen({super.key});

  @override
  ConsumerState<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends ConsumerState<SyncQueueScreen> {
  @override
  Widget build(BuildContext context) {
    final localStorage = ref.watch(localStorageProvider);
    final isSyncing = ref.watch(syncStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pendingScores = localStorage?.getPendingScores() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrian Sinkronisasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: pendingScores.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_done_rounded,
                    size: 64,
                    color: AppTheme.success.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Semua data sudah tersinkronisasi',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppTheme.onSurfaceVariantDark : AppTheme.onSurfaceVariantLight,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingScores.length,
              itemBuilder: (context, index) {
                final score = pendingScores[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.warning,
                      child: Icon(Icons.sync_problem_rounded, color: Colors.white),
                    ),
                    title: Text('Santri ID: ${score['student_id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Nilai: ${score['total_score']} - ${score['grade']}'),
                    trailing: const Icon(Icons.cloud_off_rounded, color: AppTheme.error),
                  ),
                );
              },
            ),
      bottomNavigationBar: pendingScores.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: isSyncing
                      ? null
                      : () async {
                          await ref.read(syncStateProvider.notifier).syncNow();
                          setState(() {}); // Refresh local storage UI
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isSyncing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Sinkronkan Sekarang', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          : null,
    );
  }
}
