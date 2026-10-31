import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.radius = 22,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppSemanticColors.of(context);
    final tint = accent ?? AppPalette.of(context).accent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.glassSurface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: tint.withOpacity(.18)),
            boxShadow: [
              BoxShadow(
                  color: tint.withOpacity(.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}

class NutriLensBrand extends StatelessWidget {
  const NutriLensBrand({super.key, this.compact = false, this.onTap});
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppPalette.of(context).accent;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: 'NutriLens',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CustomPaint(size: const Size(29, 27), painter: _LensMark(accent)),
            if (!compact) ...[
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NutriLens',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        letterSpacing: .2,
                        color: textColor)),
                Text('See Food. Know Nutrition.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 8.5,
                        letterSpacing: .1,
                        color: AppSemanticColors.of(context).muted)),
              ])
            ]
          ]),
        ),
      ),
    );
  }
}

class _LensMark extends CustomPainter {
  const _LensMark(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()
      ..moveTo(2, 3)
      ..lineTo(size.width - 2, 3)
      ..lineTo(size.width / 2, size.height - 2)
      ..close();
    final inner = Path()
      ..moveTo(8, 8)
      ..lineTo(size.width - 8, 8)
      ..lineTo(size.width / 2, size.height - 7)
      ..close();
    canvas.drawPath(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = color);
    canvas.drawPath(inner, Paint()..color = color.withOpacity(.30));
  }

  @override
  bool shouldRepaint(covariant _LensMark oldDelegate) =>
      oldDelegate.color != color;
}
