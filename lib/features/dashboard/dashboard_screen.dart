import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/assignment_model.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/assignment_provider.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/providers/sync_provider.dart';
import '../../app.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(assignmentProvider.notifier).loadAssignments(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final assignments = ref.watch(assignmentProvider);
    final totalStats = ref.watch(totalStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    
    // Trigger auto-sync
    ref.watch(autoSyncProvider);
    final isSyncing = ref.watch(syncStateProvider);

    // Find assignment to resume
    final resumeAssignment = assignments.cast<AssignmentModel?>().firstWhere(
      (a) => a != null && a.scoredStudents > 0 && a.scoredStudents < a.totalStudents,
      orElse: () => null,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // ── App Bar ─────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor:
                  isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              surfaceTintColor: Colors.transparent,
              actions: [
                IconButton(
                  icon: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                  tooltip: 'Ganti tema',
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).state =
                        themeMode == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                  },
                ),
                if (isSyncing)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Center(
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.cloud_sync_rounded),
                  tooltip: 'Antrian Sinkronisasi',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/sync-queue');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person_rounded),
                  tooltip: 'Profil',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/profile');
                  },
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(context, user?.fullName ?? '', isDark),
              ),
            ),

            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stats Row ──────────────────────────────────────────
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total Santri',
                          value: totalStats['total'].toString(),
                          icon: Icons.people_alt_outlined,
                          color: AppTheme.secondary,
                          animDelay: 100,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Sudah Dinilai',
                          value: totalStats['scored'].toString(),
                          icon: Icons.check_circle_outline_rounded,
                          color: AppTheme.success,
                          animDelay: 150,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Belum Dinilai',
                          value: totalStats['remaining'].toString(),
                          icon: Icons.pending_outlined,
                          color: AppTheme.warning,
                          animDelay: 200,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                  // ── Resume Banner ──────────────────────────────────────
                  if (resumeAssignment != null) ...[
                    Animate(
                      effects: [
                        FadeEffect(duration: 400.ms, delay: 100.ms),
                        SlideEffect(begin: const Offset(0, 0.2), duration: 400.ms),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary.withValues(alpha: 0.1), AppTheme.primary.withValues(alpha: 0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Lanjutkan Penilaian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kelas ${resumeAssignment.className} - ${resumeAssignment.periodName}',
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.push('/students/${resumeAssignment.classId}?assignmentId=${resumeAssignment.id}');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Lanjut'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Section Title ──────────────────────────────────────
                  Animate(
                    effects: [
                      FadeEffect(duration: 300.ms, delay: 250.ms),
                    ],
                    child: Row(
                      children: [
                        Text(
                          'Tugas Hari Ini',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${assignments.length} kelas',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Assignment Cards ────────────────────────────────────
                  if (assignments.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ...assignments.asMap().entries.map((entry) {
                      return _AssignmentCard(
                        assignment: entry.value,
                        index: entry.key,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push(
                            '/students/${entry.value.classId}?assignmentId=${entry.value.id}',
                          );
                        },
                      );
                    }),

                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, String name, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF064E3B),
                  const Color(0xFF065F46),
                ]
              : [
                  const Color(0xFF059669),
                  const Color(0xFF10B981),
                ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Animate(
            effects: [FadeEffect(duration: 400.ms)],
            child: Text(
              'Assalamu\'alaikum,',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Animate(
            effects: [
              FadeEffect(duration: 400.ms, delay: 100.ms),
              SlideEffect(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
                duration: 400.ms,
                delay: 100.ms,
              ),
            ],
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Animate(
      effects: [
        FadeEffect(duration: 500.ms, delay: 300.ms),
        SlideEffect(begin: const Offset(0, 0.05), duration: 500.ms, delay: 300.ms, curve: Curves.easeOut),
      ],
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2939) : const Color(0xFFF1F5F9),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.15),
                        AppTheme.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.coffee_rounded,
                    size: 32,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Yeay, Bebas Tugas! 🎉',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada kelas yang perlu Anda nilai saat ini.\nSantai sejenak sambil ngopi, atau hubungi Admin jika ini adalah kesalahan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppTheme.onSurfaceVariantDark
                    : AppTheme.onSurfaceVariantLight,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  ref.read(assignmentProvider.notifier).loadAssignments(user.id);
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Cek Tugas Baru'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assignment Card ────────────────────────────────────────────────────────

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final int index;
  final VoidCallback onTap;

  const _AssignmentCard({
    required this.assignment,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = assignment.progressPercentage;
    final isComplete = assignment.isComplete;

    return Animate(
      effects: [
        FadeEffect(duration: 350.ms, delay: (index * 80 + 300).ms),
        SlideEffect(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
          duration: 400.ms,
          delay: (index * 80 + 300).ms,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isComplete
                ? AppTheme.primary.withValues(alpha: 0.3)
                : (isDark
                    ? const Color(0xFF1E2939)
                    : const Color(0xFFE2E8F0)),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isComplete
                  ? AppTheme.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            splashColor: AppTheme.primary.withValues(alpha: 0.06),
            highlightColor: AppTheme.primary.withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Class icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isComplete
                                ? [AppTheme.primary, AppTheme.primaryDark]
                                : [
                                    const Color(0xFF6366F1),
                                    const Color(0xFF4F46E5),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            assignment.className,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment.levelName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppTheme.onSurfaceVariantDark
                                    : AppTheme.onSurfaceVariantLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kelas ${assignment.className}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              assignment.periodName,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppTheme.onSurfaceVariantDark
                                    : AppTheme.onSurfaceVariantLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Complete badge
                      if (isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: AppTheme.success,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Selesai',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress
                  Row(
                    children: [
                      Text(
                        '${assignment.scoredStudents}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        ' / ${assignment.totalStudents} santri dinilai',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.onSurfaceVariantDark
                              : AppTheme.onSurfaceVariantLight,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isComplete
                              ? AppTheme.success
                              : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: isDark
                          ? AppTheme.surfaceVariantDark
                          : AppTheme.surfaceVariantLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? AppTheme.success : AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: isComplete
                        ? OutlinedButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.visibility_outlined,
                                size: 16),
                            label: const Text('Lihat Detail'),
                          )
                        : ElevatedButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 16),
                            label: Text(assignment.scoredStudents > 0
                                ? 'Lanjut Penilaian'
                                : 'Mulai Penilaian'),
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
