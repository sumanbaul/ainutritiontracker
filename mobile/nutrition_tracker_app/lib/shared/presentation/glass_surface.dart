import 'dart:ui';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 28,
    this.blur = 22,
    this.opacity = .62,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius, blur, opacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppSemanticColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: colors.glassSurface.withOpacity(opacity.clamp(0, 1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: colors.glassBorder),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class AnimatedCount extends StatelessWidget {
  const AnimatedCount(this.value,
      {super.key, this.suffix = '', this.style, this.duration});
  final double value;
  final String suffix;
  final TextStyle? style;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: reduce
          ? Duration.zero
          : duration ?? const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (_, animated, __) =>
          Text('${animated.toStringAsFixed(0)}$suffix', style: style),
    );
  }
}
