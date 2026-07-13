import 'package:flutter/material.dart';

/// Frosted glass effect container for cards and overlays.
class GlassContainer extends StatelessWidget {
  final Widget? child;
  final double borderRadius;
  final double blurIntensity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? tint;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    this.child,
    this.borderRadius = 12,
    this.blurIntensity = 10,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.tint,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTint =
        tint ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveTint.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}
