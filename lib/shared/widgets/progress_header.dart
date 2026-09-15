import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class ProgressHeader extends StatelessWidget {
  final int total;
  final int scored;
  final int pending;

  const ProgressHeader({
    super.key,
    required this.total,
    required this.scored,
    required this.pending,
  });

  double get progress => total > 0 ? scored / total : 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Animate(
      effects: [
        FadeEffect(duration: 300.ms),
        SlideEffect(
          begin: const Offset(0, -0.05),
          end: Offset.zero,
          duration: 350.ms,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E2939)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _StatPill(
                  value: total.toString(),
                  label: 'Total',
                  color: isDark
                      ? AppTheme.onSurfaceVariantDark
                      : AppTheme.onSurfaceVariantLight,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  value: scored.toString(),
                  label: 'Sudah',
                  color: AppTheme.success,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  value: pending.toString(),
                  label: 'Belum',
                  color: AppTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? AppTheme.surfaceVariantDark
                          : AppTheme.surfaceVariantLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _progressColor(progress),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _progressColor(progress),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _progressColor(double p) {
    if (p >= 1.0) return AppTheme.success;
    if (p >= 0.7) return AppTheme.info;
    return AppTheme.warning;
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
