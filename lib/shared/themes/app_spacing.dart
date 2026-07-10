import 'package:flutter/material.dart';

/// Centralized spacing system for the SUMIC application.
/// Provides consistent margins, paddings, and pre-built spacers.
abstract class AppSpacing {
  // --- BASE SPACING DOUBLES ---
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // --- HEIGHT SPACERS ---
  static const SizedBox heightXxs = SizedBox(height: xxs);
  static const SizedBox heightXs = SizedBox(height: xs);
  static const SizedBox heightSm = SizedBox(height: sm);
  static const SizedBox heightMd = SizedBox(height: md);
  static const SizedBox heightLg = SizedBox(height: lg);
  static const SizedBox heightXl = SizedBox(height: xl);
  static const SizedBox heightXxl = SizedBox(height: xxl);
  static const SizedBox heightXxxl = SizedBox(height: xxxl);

  // --- WIDTH SPACERS ---
  static const SizedBox widthXxs = SizedBox(width: xxs);
  static const SizedBox widthXs = SizedBox(width: xs);
  static const SizedBox widthSm = SizedBox(width: sm);
  static const SizedBox widthMd = SizedBox(width: md);
  static const SizedBox widthLg = SizedBox(width: lg);
  static const SizedBox widthXl = SizedBox(width: xl);
  static const SizedBox widthXxl = SizedBox(width: xxl);
  static const SizedBox widthXxxl = SizedBox(width: xxxl);

  // --- EDGE INSETS TEMPLATES ---
  static const EdgeInsets edgeInsetsAllZero = EdgeInsets.zero;
  static const EdgeInsets edgeInsetsAllXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsAllSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsAllMd = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsAllLg = EdgeInsets.all(lg);

  static const EdgeInsets edgeInsetsHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets edgeInsetsHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets edgeInsetsHorizontalLg = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets edgeInsetsVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets edgeInsetsVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets edgeInsetsVerticalLg = EdgeInsets.symmetric(vertical: lg);
}
