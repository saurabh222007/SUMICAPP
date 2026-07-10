import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Glassmorphism container reflecting the Neo-Noir design tokens.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blur = 24.0,
    this.borderColor,
    this.backgroundColor = const Color(0x0DFFFFFF), // 5% White Transparency
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.06),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
