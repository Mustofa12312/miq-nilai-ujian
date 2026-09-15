import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user_model.dart';
import '../../core/services/supabase_service.dart';

/// State untuk autentikasi
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  /// Cek sesi yang sudah ada saat aplikasi dibuka
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final session = supabaseAuth.currentSession;
      if (session != null) {
        final profile = await _fetchProfile(session.user.id);
        state = state.copyWith(user: profile, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }

    // Dengarkan perubahan auth state (login/logout dari tab lain, token refresh, dll)
    supabaseAuth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        final profile = await _fetchProfile(session.user.id);
        if (mounted) state = state.copyWith(user: profile);
      } else {
        if (mounted) state = const AuthState();
      }
    });
  }

  /// Ambil profil pengguna dari tabel `profiles`
  Future<UserModel?> _fetchProfile(String userId) async {
    try {
      final data = await supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();
      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await supabaseAuth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Login gagal. Periksa email dan password Anda.',
        );
        return false;
      }

      final profile = await _fetchProfile(response.user!.id);

      if (profile == null) {
        // User ada di auth tapi tidak punya profil di tabel profiles
        await supabaseAuth.signOut();
        state = state.copyWith(
          isLoading: false,
          error: 'Akun tidak ditemukan dalam sistem. Hubungi administrator.',
        );
        return false;
      }

      // Pastikan role adalah penguji (atau admin) — bukan pimpinan
      if (profile.role == UserRole.leader) {
        await supabaseAuth.signOut();
        state = state.copyWith(
          isLoading: false,
          error: 'Akun Pimpinan tidak dapat login ke aplikasi penguji.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        user: profile,
        clearError: true,
      );
      return true;
    } on Exception catch (e) {
      final message = _parseAuthError(e.toString());
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<void> logout() async {
    await supabaseAuth.signOut();
    state = const AuthState();
  }

  String _parseAuthError(String error) {
    if (error.contains('Invalid login credentials') ||
        error.contains('invalid_credentials')) {
      return 'Email atau password salah.';
    }
    if (error.contains('Email not confirmed')) {
      return 'Email belum dikonfirmasi.';
    }
    if (error.contains('network') || error.contains('SocketException')) {
      return 'Tidak ada koneksi internet.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
