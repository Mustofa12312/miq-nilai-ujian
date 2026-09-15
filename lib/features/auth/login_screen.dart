import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'ahmad@miq.sch.id');
  final _passCtrl = TextEditingController(text: 'password123');
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Background gradient
            Container(
              height: size.height * 0.55,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF047857),
                    Color(0xFF059669),
                    Color(0xFF10B981),
                  ],
                ),
              ),
            ),

            // Decorative circles
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 80,
              right: 60,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              top: 160,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Logo & Title
                    Animate(
                      effects: [
                        FadeEffect(duration: 500.ms),
                        SlideEffect(
                          begin: const Offset(0, -0.1),
                          end: Offset.zero,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        ),
                      ],
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '📖',
                                style: TextStyle(fontSize: 38),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'MIQ Assessment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sistem Penilaian Al-Qur\'an',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Card Form
                    Animate(
                      effects: [
                        FadeEffect(duration: 500.ms, delay: 150.ms),
                        SlideEffect(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                          duration: 500.ms,
                          delay: 150.ms,
                          curve: Curves.easeOutCubic,
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.surfaceDark
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Masuk',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gunakan akun yang diberikan admin',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppTheme.onSurfaceVariantDark
                                      : AppTheme.onSurfaceVariantLight,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Email
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) => (v?.isEmpty ?? true)
                                    ? 'Email wajib diisi'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Password
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => (v?.isEmpty ?? true)
                                    ? 'Password wajib diisi'
                                    : null,
                              ),

                              // Error message
                              if (authState.error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.error.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: AppTheme.error,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          authState.error!,
                                          style: const TextStyle(
                                            color: AppTheme.error,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 28),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: authState.isLoading
                                      ? null
                                      : _handleLogin,
                                  child: authState.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text('Masuk'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Version
                    Animate(
                      effects: [FadeEffect(duration: 400.ms, delay: 400.ms)],
                      child: Text(
                        'MIQ Smart Assessment System v1.0',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.onSurfaceVariantDark
                              : AppTheme.onSurfaceVariantLight,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
