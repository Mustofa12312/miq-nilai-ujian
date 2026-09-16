import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/student_model.dart';
import 'grade_badge.dart';

class StudentListTile extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;
  final int index;

  const StudentListTile({
    super.key,
    required this.student,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final isScored = student.isScored;

    return Animate(
      effects: [
        FadeEffect(duration: 200.ms, delay: (index * 30).ms),
        SlideEffect(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
          duration: 250.ms,
          delay: (index * 30).ms,
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isScored
                ? AppTheme.primary.withValues(alpha: 0.25)
                : (isDark
                    ? const Color(0xFF1E2939)
                    : const Color(0xFFE2E8F0)),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isScored
                  ? AppTheme.primary.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(18),
            splashColor: AppTheme.primary.withValues(alpha: 0.08),
            highlightColor: AppTheme.primary.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Avatar
                  _buildAvatar(isDark, isScored),
                  const SizedBox(width: 14),
                  // Name & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.onSurfaceDark
                                : AppTheme.onSurfaceLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (student.nis != null || student.gender != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (student.nis != null && student.nis!.isNotEmpty) 'NIS: ${student.nis}',
                              if (student.gender != null && student.gender!.isNotEmpty) student.gender,
                            ].join(' • '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppTheme.onSurfaceVariantDark : AppTheme.onSurfaceVariantLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: student.isLocked
                                    ? AppTheme.error
                                    : (isScored ? AppTheme.success : AppTheme.warning),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              student.isLocked
                                  ? 'Terkunci'
                                  : (isScored ? 'Sudah Dinilai' : 'Belum Dinilai'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: student.isLocked
                                    ? AppTheme.error
                                    : (isScored ? AppTheme.success : AppTheme.warning),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Score badge or chevron
                  if (isScored && student.grade != null) ...[
                    GradeBadge(grade: student.grade!),
                    if (student.isLocked) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lock_rounded, color: AppTheme.error, size: 20),
                    ]
                  ] else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppTheme.onSurfaceVariantDark
                          : AppTheme.onSurfaceVariantLight,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark, bool isScored) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isScored
                  ? [AppTheme.primary, AppTheme.primaryDark]
                  : [
                      const Color(0xFF94A3B8),
                      const Color(0xFF64748B),
                    ],
            ),
          ),
          child: Center(
            child: Text(
              student.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
