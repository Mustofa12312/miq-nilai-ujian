import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/scoring_provider.dart';

class CriteriaRow extends StatefulWidget {
  final CriteriaEntry entry;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int index;

  const CriteriaRow({
    super.key,
    required this.entry,
    required this.onIncrement,
    required this.onDecrement,
    this.index = 0,
  });

  @override
  State<CriteriaRow> createState() => _CriteriaRowState();
}

class _CriteriaRowState extends State<CriteriaRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scoreAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(CriteriaRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.score != widget.entry.score) {
      _animateScore();
    }
  }

  void _animateScore() {
    _scoreAnimation = Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.elasticOut),
    );
    _scoreController.forward(from: 0);
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entry = widget.entry;
    final score = entry.score;
    final maxScore = entry.criteria.defaultScore;
    final isMaxMistakes = entry.mistakes >= entry.criteria.maxMistakes;
    final isZeroMistakes = entry.mistakes == 0;

    // Score color
    Color scoreColor;
    final pct = score / maxScore;
    if (pct >= 0.9) {
      scoreColor = AppTheme.success;
    } else if (pct >= 0.7) {
      scoreColor = AppTheme.warning;
    } else {
      scoreColor = AppTheme.error;
    }

    return Animate(
      effects: [
        FadeEffect(duration: 200.ms, delay: (widget.index * 40).ms),
        SlideEffect(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
          duration: 250.ms,
          delay: (widget.index * 40).ms,
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceVariantDark : AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: entry.mistakes > 0
                ? AppTheme.warning.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Criteria name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.criteria.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.onSurfaceDark
                          : AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.criteria.deduction.toInt()}pts / kesalahan',
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

            // Counter controls
            Row(
              children: [
                _CounterButton(
                  icon: Icons.remove_rounded,
                  onTap: isZeroMistakes
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          widget.onDecrement();
                        },
                  enabled: !isZeroMistakes,
                  isDark: isDark,
                ),
                Container(
                  width: 44,
                  alignment: Alignment.center,
                  child: Text(
                    entry.mistakes.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: entry.mistakes > 0
                          ? AppTheme.warning
                          : (isDark
                              ? AppTheme.onSurfaceDark
                              : AppTheme.onSurfaceLight),
                    ),
                  ),
                ),
                _CounterButton(
                  icon: Icons.add_rounded,
                  onTap: isMaxMistakes
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          widget.onIncrement();
                        },
                  enabled: !isMaxMistakes,
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Score
            AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scoreAnimation.value,
                  child: SizedBox(
                    width: 40,
                    child: Text(
                      score.toInt().toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDark;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.isDark,
  });

  @override
  State<_CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<_CounterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled
        ? AppTheme.primary
        : (widget.isDark
            ? AppTheme.onSurfaceVariantDark
            : AppTheme.onSurfaceVariantLight);

    return GestureDetector(
      onTapDown: widget.enabled
          ? (_) => _controller.forward()
          : null,
      onTapUp: widget.enabled
          ? (_) {
              _controller.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.enabled
                ? AppTheme.primary.withOpacity(widget.isDark ? 0.2 : 0.1)
                : Colors.transparent,
            border: Border.all(
              color: color.withOpacity(widget.enabled ? 0.4 : 0.2),
              width: 1.5,
            ),
          ),
          child: Icon(widget.icon, size: 18, color: color),
        ),
      ),
    );
  }
}
