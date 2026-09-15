import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class GradeBadge extends StatelessWidget {
  final String grade;
  final bool large;

  const GradeBadge({super.key, required this.grade, this.large = false});

  Color get _color {
    switch (grade) {
      case 'Mumtaz':
        return const Color(0xFF059669); // Emerald
      case 'Jayyid Jiddan':
        return const Color(0xFF0EA5E9); // Sky
      case 'Jayyid':
        return const Color(0xFF6366F1); // Indigo
      case 'Maqbul':
        return const Color(0xFFF59E0B); // Amber
      case 'I\'adah':
        return const Color(0xFFEF4444); // Red
      default:
        return AppTheme.onSurfaceVariantLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _color.withValues(alpha: 0.12);
    final fontSize = large ? 18.0 : 12.0;
    final padding = large
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? _color.withValues(alpha: 0.2) : bgColor,
        borderRadius: BorderRadius.circular(large ? 14 : 8),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        grade,
        style: TextStyle(
          color: _color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Circular grade indicator for the scoring summary
class GradeCircle extends StatelessWidget {
  final double percentage;
  final String grade;
  final double totalScore;

  const GradeCircle({
    super.key,
    required this.percentage,
    required this.grade,
    required this.totalScore,
  });

  Color get _gradeColor {
    if (percentage >= 90) return const Color(0xFF059669);
    if (percentage >= 80) return const Color(0xFF0EA5E9);
    if (percentage >= 70) return const Color(0xFF6366F1);
    if (percentage >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 8,
                backgroundColor: isDark
                    ? AppTheme.surfaceVariantDark
                    : AppTheme.surfaceVariantLight,
                valueColor: AlwaysStoppedAnimation<Color>(_gradeColor),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              children: [
                Text(
                  totalScore.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _gradeColor,
                    height: 1,
                  ),
                ),
                Text(
                  '/ 140',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.onSurfaceVariantDark
                        : AppTheme.onSurfaceVariantLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ).animate().scale(
          duration: 400.ms,
          curve: Curves.elasticOut,
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
        ),
        const SizedBox(height: 8),
        GradeBadge(grade: grade, large: true),
      ],
    );
  }
}
