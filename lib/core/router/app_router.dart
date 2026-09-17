import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/students/students_screen.dart';
import '../../features/scoring/scoring_screen.dart';
import '../../features/sync/sync_queue_screen.dart';
import '../../features/profile/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/dashboard' : '/login',
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: '/sync-queue',
        name: 'sync-queue',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SyncQueueScreen(),
          transitionsBuilder: _slideLeftTransition,
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileScreen(),
          transitionsBuilder: _slideLeftTransition,
        ),
      ),
      GoRoute(
        path: '/students/:classId',
        name: 'students',
        pageBuilder: (context, state) {
          final classId = int.parse(state.pathParameters['classId']!);
          final assignmentId =
              int.tryParse(state.uri.queryParameters['assignmentId'] ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: StudentsScreen(
              classId: classId,
              assignmentId: assignmentId,
            ),
            transitionsBuilder: _slideLeftTransition,
          );
        },
      ),
      GoRoute(
        path: '/scoring/:studentId',
        name: 'scoring',
        pageBuilder: (context, state) {
          final studentId = int.parse(state.pathParameters['studentId']!);
          final classId =
              int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
          final assignmentId =
              int.tryParse(state.uri.queryParameters['assignmentId'] ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ScoringScreen(
              studentId: studentId,
              classId: classId,
              assignmentId: assignmentId,
            ),
            transitionsBuilder: _slideLeftTransition,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.error}'),
      ),
    ),
  );
});

// ── Transition Builders ────────────────────────────────────────────────────

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: FadeTransition(opacity: animation, child: child),
  );
}

Widget _slideLeftTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: FadeTransition(opacity: animation, child: child),
  );
}
