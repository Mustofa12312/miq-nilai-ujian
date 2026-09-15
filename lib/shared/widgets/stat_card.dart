import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final int animDelay;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.animDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? AppTheme.primary;

    return Animate(
      effects: [
        FadeEffect(duration: 300.ms, delay: animDelay.ms),
        SlideEffect(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
          duration: 350.ms,
          delay: animDelay.ms,
          curve: Curves.easeOutCubic,
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
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cardColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: cardColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
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
      ),
    );
  }
}
