import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A rounded box with a coloured gradient border and a solid surface fill.
/// Reused for cards, editor fields and the filter bar.
class GradientBorderBox extends StatelessWidget {
  const GradientBorderBox({
    super.key,
    required this.child,
    this.gradient,
    this.borderWidth = 1.5,
    this.radius = 18,
    this.padding = EdgeInsets.zero,
    this.fill,
    this.onTap,
  });

  final Widget child;
  final Gradient? gradient;
  final double borderWidth;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? fill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final grad = gradient ??
        const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: grad.colors.first.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: Material(
          color: fill ?? AppTheme.surface,
          borderRadius: BorderRadius.circular(radius - borderWidth),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
