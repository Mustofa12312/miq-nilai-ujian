import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

import '../../shared/models/student_model.dart';
import '../../shared/providers/assignment_provider.dart';
import '../../shared/providers/scoring_provider.dart';
import '../../shared/providers/student_provider.dart';
import '../../shared/widgets/criteria_row.dart';
import '../../shared/widgets/grade_badge.dart';


class ScoringScreen extends ConsumerStatefulWidget {
  final int studentId;
  final int classId;

  const ScoringScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen>
    with TickerProviderStateMixin {
  late AnimationController _successController;
  late Animation<double> _successScale;
  late Animation<double> _successOpacity;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(scoringProvider.notifier).initForStudent();
    });
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    HapticFeedback.mediumImpact();

    final scoring = ref.read(scoringProvider);
    final success = await ref
        .read(scoringProvider.notifier)
        .saveScore(widget.studentId, widget.classId);

    if (success) {
      // Update student state
      ref.read(studentProvider.notifier).markAsScored(
            widget.studentId,
            scoring.totalScore,
            scoring.grade,
          );

      // Update assignment progress
      ref
          .read(assignmentProvider.notifier)
          .updateScoredCount(widget.classId);

      // Show success animation
      setState(() => _showSuccess = true);
      _successController.forward();
      HapticFeedback.heavyImpact();

      // Auto navigate back after 1.8 seconds
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) {
        _successController.reset();
        setState(() => _showSuccess = false);
        ref.read(scoringProvider.notifier).reset();
        context.pop();
      }
    } else {
      // Tampilkan error jika ada
      final error = ref.read(scoringProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoringState = ref.watch(scoringProvider);
    final studentState = ref.watch(studentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    StudentModel? student;
    try {
      student = studentState.students.firstWhere((s) => s.id == widget.studentId);
    } catch (_) {}

    final assignment = ref
        .watch(assignmentProvider.notifier)
        .getByClassId(widget.classId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student?.fullName ?? 'Santri',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${assignment?.levelName ?? ''} · Kelas ${assignment?.className ?? ''}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.onSurfaceVariantDark
                    : AppTheme.onSurfaceVariantLight,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ── Main Content ──────────────────────────────────────────────
          scoringState.isLoadingCriteria
              ? const Center(child: CircularProgressIndicator())
              : scoringState.entries.isEmpty
                  ? Center(
                      child: Text(
                        scoringState.error ?? 'Tidak ada kriteria penilaian.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _buildContent(context, scoringState, isDark),

          // ── Floating Total Bar ────────────────────────────────────────
          if (scoringState.entries.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _TotalBar(
                scoringState: scoringState,
                isDark: isDark,
                isSaving: scoringState.isSaving,
                onSave: _handleSave,
              ),
            ),

          // ── Success Overlay ───────────────────────────────────────────
          if (_showSuccess)
            _SuccessOverlay(
              scale: _successScale,
              opacity: _successOpacity,
              grade: scoringState.grade,
              totalScore: scoringState.totalScore,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScoringState scoringState,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TAJWID Section ──────────────────────────────────────────
          _SectionHeader(
            title: 'Tajwid',
            icon: '🕌',
            total: scoringState.tajwidEntries
                .fold(0.0, (s, e) => s + e.score),
            max: scoringState.tajwidEntries
                .fold(0.0, (s, e) => s + e.criteria.defaultScore),
            animDelay: 0,
          ),
          const SizedBox(height: 10),
          ...scoringState.tajwidEntries.asMap().entries.map((entry) {
            return CriteriaRow(
              entry: entry.value,
              index: entry.key,
              onIncrement: () => ref
                  .read(scoringProvider.notifier)
                  .incrementMistakes(entry.value.criteria.id),
              onDecrement: () => ref
                  .read(scoringProvider.notifier)
                  .decrementMistakes(entry.value.criteria.id),
            );
          }),

          const SizedBox(height: 20),

          // ── FASOHAH Section ─────────────────────────────────────────
          _SectionHeader(
            title: 'Fasohah',
            icon: '📖',
            total: scoringState.fasohahEntries
                .fold(0.0, (s, e) => s + e.score),
            max: scoringState.fasohahEntries
                .fold(0.0, (s, e) => s + e.criteria.defaultScore),
            animDelay: 200,
          ),
          const SizedBox(height: 10),
          ...scoringState.fasohahEntries.asMap().entries.map((entry) {
            return CriteriaRow(
              entry: entry.value,
              index: entry.key + 4,
              onIncrement: () => ref
                  .read(scoringProvider.notifier)
                  .incrementMistakes(entry.value.criteria.id),
              onDecrement: () => ref
                  .read(scoringProvider.notifier)
                  .decrementMistakes(entry.value.criteria.id),
            );
          }),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String icon;
  final double total;
  final double max;
  final int animDelay;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.total,
    required this.max,
    required this.animDelay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = max > 0 ? total / max : 0.0;

    Color color;
    if (pct >= 0.9) {
      color = AppTheme.success;
    } else if (pct >= 0.7) {
      color = AppTheme.warning;
    } else {
      color = AppTheme.error;
    }

    return Animate(
      effects: [
        FadeEffect(duration: 300.ms, delay: animDelay.ms),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDark
                ? [
                    AppTheme.primary.withValues(alpha: 0.15),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ]
                : [
                    AppTheme.primarySurface,
                    AppTheme.primarySurface.withValues(alpha: 0.3),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark
                    ? AppTheme.onSurfaceDark
                    : AppTheme.onSurfaceLight,
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                '${total.toInt()} / ${max.toInt()}',
                key: ValueKey(total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Total Bar ──────────────────────────────────────────────────────────────

class _TotalBar extends StatelessWidget {
  final ScoringState scoringState;
  final bool isDark;
  final bool isSaving;
  final VoidCallback onSave;

  const _TotalBar({
    required this.scoringState,
    required this.isDark,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final pct = scoringState.percentage;
    Color gradeColor;
    if (pct >= 90) {
      gradeColor = AppTheme.success;
    } else if (pct >= 80) {
      gradeColor = const Color(0xFF0EA5E9);
    } else if (pct >= 70) {
      gradeColor = AppTheme.secondary;
    } else if (pct >= 60) {
      gradeColor = AppTheme.warning;
    } else {
      gradeColor = AppTheme.error;
    }

    return Animate(
      effects: [
        SlideEffect(
          begin: const Offset(0, 1),
          end: Offset.zero,
          duration: 500.ms,
          delay: 400.ms,
          curve: Curves.easeOutCubic,
        ),
        FadeEffect(duration: 400.ms, delay: 400.ms),
      ],
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.onSurfaceVariantDark.withValues(alpha: 0.3)
                    : AppTheme.onSurfaceVariantLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Score display
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Nilai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppTheme.onSurfaceVariantDark
                            : AppTheme.onSurfaceVariantLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: child,
                      ),
                      child: Text(
                        scoringState.totalScore.toInt().toString(),
                        key: ValueKey(scoringState.totalScore),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: gradeColor,
                          height: 1,
                        ),
                      ),
                    ),
                    Text(
                      'dari ${scoringState.maxPossibleScore.toInt()} poin',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.onSurfaceVariantDark
                            : AppTheme.onSurfaceVariantLight,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GradeCircle(
                  percentage: pct,
                  grade: scoringState.grade,
                  totalScore: scoringState.totalScore,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Menyimpan...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Simpan Nilai',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

// ── Success Overlay ────────────────────────────────────────────────────────

class _SuccessOverlay extends StatelessWidget {
  final Animation<double> scale;
  final Animation<double> opacity;
  final String grade;
  final double totalScore;
  final bool isDark;

  const _SuccessOverlay({
    required this.scale,
    required this.opacity,
    required this.grade,
    required this.totalScore,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: AnimatedBuilder(
          animation: opacity,
          builder: (context, child) => Opacity(
            opacity: opacity.value,
            child: child,
          ),
          child: AnimatedBuilder(
            animation: scale,
            builder: (context, child) => Transform.scale(
              scale: scale.value,
              child: child,
            ),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nilai Tersimpan!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${totalScore.toInt()} poin',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.onSurfaceVariantDark
                          : AppTheme.onSurfaceVariantLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GradeBadge(grade: grade, large: true),
                  const SizedBox(height: 16),
                  Text(
                    'Kembali ke daftar santri...',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.onSurfaceVariantDark
                          : AppTheme.onSurfaceVariantLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


