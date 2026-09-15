import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/local_storage_service.dart';

final localStorageProvider = Provider<LocalStorageService?>((ref) {
  // Provider ini akan di-override di main.dart setelah init
  return null;
});
