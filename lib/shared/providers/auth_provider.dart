import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user_model.dart';
import '../../core/constants/app_constants.dart';

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
  AuthNotifier() : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));

    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Email dan password tidak boleh kosong',
      );
      return false;
    }

    if (password.length < 4) {
      state = state.copyWith(
        isLoading: false,
        error: 'Password terlalu pendek',
      );
      return false;
    }

    // Mock: accept any valid-looking credentials
    state = state.copyWith(
      isLoading: false,
      user: AppConstants.mockExaminer,
      clearError: true,
    );
    return true;
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
