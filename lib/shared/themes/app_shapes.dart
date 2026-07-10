import 'package:flutter/material.dart';

/// Centralized shapes, border radius, and elevation tokens for the SUMIC application.
abstract class AppShapes {
  // --- BORDER RADIUS DOUBLES ---
  static const double rXs = 4.0;
  static const double rSm = 8.0;
  static const double rMd = 12.0;
  static const double rLg = 16.0;
  static const double rXl = 24.0;
  static const double rPill = 999.0;

  // --- BORDER RADIUS OBJECTS ---
  static final BorderRadius radiusXs = BorderRadius.circular(rXs);
  static final BorderRadius radiusSm = BorderRadius.circular(rSm);
  static final BorderRadius radiusMd = BorderRadius.circular(rMd);
  static final BorderRadius radiusLg = BorderRadius.circular(rLg);
  static final BorderRadius radiusXl = BorderRadius.circular(rXl);
  static final BorderRadius radiusPill = BorderRadius.circular(rPill);

  // --- SHAPES ---
  static final RoundedRectangleBorder shapeXs = RoundedRectangleBorder(borderRadius: radiusXs);
  static final RoundedRectangleBorder shapeSm = RoundedRectangleBorder(borderRadius: radiusSm);
  static final RoundedRectangleBorder shapeMd = RoundedRectangleBorder(borderRadius: radiusMd);
  static final RoundedRectangleBorder shapeLg = RoundedRectangleBorder(borderRadius: radiusLg);
  static final RoundedRectangleBorder shapeXl = RoundedRectangleBorder(borderRadius: radiusXl);
  static final RoundedRectangleBorder shapePill = RoundedRectangleBorder(borderRadius: radiusPill);

  // --- ELEVATION DOUBLES (M3 levels) ---
  static const double eNone = 0.0;
  static const double eL1 = 1.0;  // Cards
  static const double eL2 = 3.0;  // Dialogs
  static const double eL3 = 6.0;  // FABs / Bottom sheets
  static const double eL4 = 8.0;
  static const double eL5 = 12.0;
}
