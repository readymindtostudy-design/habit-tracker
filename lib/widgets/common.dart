import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';

/// Thin progress bar used inside habit cards.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double w =
                c.maxWidth * value.clamp(0.0, 1.0).toDouble();
            return Stack(
              children: <Widget>[
                Container(color: AppColors.card2),
                SizedBox(
                  width: w,
                  child: Container(color: color),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - stroke) / 2;
    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    final Paint arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0).toDouble(),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Circular progress ring with an optional centre child.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 260,
    this.stroke = 14,
    this.trackColor = AppColors.card2,
    this.child,
  });

  final double progress;
  final Color color;
  final double size;
  final double stroke;
  final Color trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              progress: progress,
              color: color,
              track: trackColor,
              stroke: stroke,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class BigRing extends StatelessWidget {
  const BigRing({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double p = total == 0 ? 0.0 : done / total;
    return ProgressRing(
      progress: p,
      color: AppColors.green,
      size: 132,
      stroke: 11,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$done/$total',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const Text(
            'done today',
            style: TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 26, 2, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    required this.color,
    this.size = 54,
  });

  final String icon;
  final String color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint(color, 0.28),
        shape: BoxShape.circle,
      ),
      child: Text(icon, style: TextStyle(fontSize: size * 0.48)),
    );
  }
}

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onAction,
    this.onMenu,
  });

  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback onAction;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final bool done = app.doneToday(habit);
    final double progress = app.todayProgress(habit);
    final Color color = hexColor(habit.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 12, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: tint(habit.color, 0.5), width: 1.4),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconBubble(icon: habit.icon, color: habit.color),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  habit.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (habit.quit) ...<Widget>[
                                const SizedBox(width: 6),
                                const Icon(Icons.block,
                                    size: 15, color: AppColors.muted),
                              ],
                            ],
                          ),
                          const SizedBox(height: 7),
                          ProgressBar(value: progress, color: color),
                          const SizedBox(height: 7),
                          Text(
                            app.progressText(habit),
                            style: TextStyle(
                              fontSize: 13.5,
                              color: done ? AppColors.green : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _action(context, app, done, color),
                    if (onMenu != null)
                      IconButton(
                        onPressed: onMenu,
                        icon: const Icon(Icons.more_vert,
                            color: Color(0xFFCFCFCF)),
                        tooltip: 'More',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(
      BuildContext context, AppState app, bool done, Color color) {
    if (habit.kind == HabitKind.tick) {
      return Material(
        color: done ? color : Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(color: color, width: 2),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onAction,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              Icons.check_rounded,
              color: done ? AppColors.greenInk : Colors.transparent,
              size: 24,
            ),
          ),
        ),
      );
    }
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onAction,
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.add_rounded,
              color: AppColors.greenInk, size: 26),
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line, width: 1.4),
      ),
      child: child,
    );
  }
}

class DonutSlice {
  const DonutSlice(this.label, this.minutes, this.color);
  final String label;
  final double minutes;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.total});
  final List<DonutSlice> slices;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double stroke = size.shortestSide * 0.17;
    final double radius = (size.shortestSide - stroke) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.card2;
    canvas.drawCircle(center, radius, track);

    if (total <= 0) return;
    double start = -math.pi / 2;
    final double gap = slices.length > 1 ? 0.05 : 0.0;
    for (final DonutSlice s in slices) {
      final double sweep = (s.minutes / total) * 2 * math.pi;
      final Paint p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = s.color;
      canvas.drawArc(rect, start + gap / 2, math.max(0, sweep - gap), false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 168,
    this.center,
  });

  final List<DonutSlice> slices;
  final double size;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final double total =
        slices.fold<double>(0, (double a, DonutSlice s) => a + s.minutes);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(slices: slices, total: total),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

/// Horizontal pill used for filter chips.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent = AppColors.green,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.09) : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? accent : AppColors.line,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[icon!, const SizedBox(width: 8)],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15.5,
                  color: selected ? accent : const Color(0xFFA8A8A8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1800),
        margin: const EdgeInsets.all(16),
      ),
    );
}
