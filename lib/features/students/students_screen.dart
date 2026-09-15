import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/assignment_provider.dart';
import '../../shared/providers/student_provider.dart';
import '../../shared/widgets/progress_header.dart';
import '../../shared/widgets/student_list_tile.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  final int classId;
  final int assignmentId;

  const StudentsScreen({
    super.key,
    required this.classId,
    required this.assignmentId,
  });

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ambil context periode dan exam_type dari assignment yang sudah di-load
      final assignment = ref
          .read(assignmentProvider.notifier)
          .getByClassId(widget.classId);
      ref.read(studentProvider.notifier).loadStudents(
            widget.classId,
            periodId: assignment?.periodId,
            examTypeId: assignment?.examTypeId,
          );
    });
    _searchCtrl.addListener(() {
      ref.read(studentProvider.notifier).updateSearch(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentState = ref.watch(studentProvider);
    final assignment = ref
        .watch(assignmentProvider.notifier)
        .getByClassId(widget.classId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = studentState.filtered;
    final pending = filtered.where((s) => !s.isScored).toList();
    final scored = filtered.where((s) => s.isScored).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelas ${assignment?.className ?? ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              assignment?.levelName ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.onSurfaceVariantDark
                    : AppTheme.onSurfaceVariantLight,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum'),
                  const SizedBox(width: 6),
                  _TabBadge(
                    count: studentState.pendingCount,
                    color: AppTheme.warning,
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah'),
                  const SizedBox(width: 6),
                  _TabBadge(
                    count: studentState.scoredCount,
                    color: AppTheme.success,
                  ),
                ],
              ),
            ),
          ],
          labelColor: AppTheme.primary,
          unselectedLabelColor: isDark
              ? AppTheme.onSurfaceVariantDark
              : AppTheme.onSurfaceVariantLight,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
        ),
      ),
      body: studentState.isLoading
          ? _buildShimmer(isDark)
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    children: [
                      // Stats header
                      ProgressHeader(
                        total: studentState.totalCount,
                        scored: studentState.scoredCount,
                        pending: studentState.pendingCount,
                      ),
                      const SizedBox(height: 12),
                      // Search
                      _SearchBar(controller: _searchCtrl, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Belum Dinilai
                      _buildList(context, pending, isDark),
                      // Tab 2: Sudah Dinilai
                      _buildList(context, scored, isDark, isScored: true),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List students,
    bool isDark, {
    bool isScored = false,
  }) {
    if (students.isEmpty) {
      return _buildEmpty(
        isDark,
        isScored ? 'Belum ada yang dinilai' : 'Semua santri sudah dinilai! 🎉',
        isScored
            ? 'Mulai nilai santri dari tab "Belum"'
            : 'Penilaian kelas ini sudah selesai.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: students.length,
      itemBuilder: (context, i) {
        final student = students[i];
        return StudentListTile(
          student: student,
          index: i,
          onTap: () {
            context.push(
              '/scoring/${student.id}?classId=${widget.classId}',
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty(bool isDark, String title, String subtitle) {
    return Center(
      child: Animate(
        effects: [FadeEffect(duration: 400.ms)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.onSurfaceVariantDark
                    : AppTheme.onSurfaceVariantLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: List.generate(
          7,
          (i) => Animate(
            effects: [
              FadeEffect(
                duration: 600.ms,
                delay: (i * 60).ms,
                curve: Curves.easeInOut,
              ),
            ],
            onPlay: (c) => c.repeat(reverse: true),
            child: Container(
              height: 74,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.surfaceVariantDark
                    : AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _TabBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const _SearchBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(duration: 300.ms, delay: 100.ms),
      ],
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Cari nama santri...',
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    controller.clear();
                    HapticFeedback.lightImpact();
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        onChanged: (_) {},
      ),
    );
  }
}
