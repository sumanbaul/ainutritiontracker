import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class NutritionHero extends StatelessWidget {
  const NutritionHero({
    super.key,
    required this.value,
    required this.target,
    required this.label,
    required this.caption,
    this.child,
  });
  final double value, target;
  final String label, caption;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: dark ? AppGradients.hero : null,
        color: dark ? null : Colors.white.withOpacity(.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? .18 : .08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(children: [
        SizedBox(
          width: 132,
          height: 132,
          child: CustomPaint(
            painter: _RingPainter(
              progress: target <= 0 ? 0 : (value / target).clamp(0, 1),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value.toStringAsFixed(0),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: dark ? Colors.white : AppColors.ink)),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.secondaryText, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(caption,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: dark ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('${target.toStringAsFixed(0)} daily target',
                  style: const TextStyle(color: AppColors.secondaryText)),
              if (child != null) ...[const SizedBox(height: 14), child!],
            ],
          ),
        ),
      ]),
    );
  }
}

class NutritionMetricCard extends StatelessWidget {
  const NutritionMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    required this.icon,
    this.unit = 'g',
  });
  final String label, unit;
  final double value, target;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: MediaQuery.sizeOf(context).width < 370
            ? (MediaQuery.sizeOf(context).width - 52) / 2
            : 158,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(.22)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.secondaryText)),
          ]),
          const SizedBox(height: 12),
          Text('${value.toStringAsFixed(0)}$unit',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: target <= 0 ? 0 : (value / target).clamp(0, 1),
              color: color,
              backgroundColor: color.withOpacity(.12),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text('of ${target.toStringAsFixed(0)}$unit',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
        ]),
      );
}

class NutritionSectionTitle extends StatelessWidget {
  const NutritionSectionTitle(this.title,
      {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            if (subtitle != null)
              Text(subtitle!,
                  style: const TextStyle(color: AppColors.secondaryText)),
          ]),
        ),
        if (action != null) action!,
      ]);
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2 - 8);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(.10);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, base);
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..shader = AppGradients.energy.createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, active);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
