import 'package:supabase_flutter/supabase_flutter.dart';

/// Satu titik akses ke Supabase client di seluruh aplikasi Flutter.
/// Gunakan [supabase] untuk mengakses client.
/// Gunakan [supabaseAuth] untuk mengakses authentication.
final supabase = Supabase.instance.client;
final supabaseAuth = Supabase.instance.client.auth;
