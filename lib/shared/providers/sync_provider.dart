import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/supabase_service.dart';
import 'local_storage_provider.dart';
import 'auth_provider.dart';

final syncServiceProvider = Provider<SyncService?>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  if (localStorage == null) return null;
  
  return SyncService(
    localStorage: localStorage,
    supabase: supabase,
  );
});

final syncStateProvider = StateProvider<bool>((ref) => false);

/// Auto-sync provider yang dijalankan ketika user berubah / aplikasi start
final autoSyncProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  final syncService = ref.watch(syncServiceProvider);
  
  if (user != null && syncService != null) {
    // Jalankan sync di background tanpa mem-block UI
    Future.microtask(() async {
      ref.read(syncStateProvider.notifier).state = true;
      await syncService.syncPendingScores(user.id);
      ref.read(syncStateProvider.notifier).state = false;
    });
  }
});
