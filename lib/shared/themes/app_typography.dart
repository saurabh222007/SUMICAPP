import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Typography system for the SUMIC application.
/// Derived from the premium Stitch design guidelines, pairing Sora for display/headings
/// and Inter for readable, precise user interface text.
abstract class AppTypography {
  // --- DISPLAY STYLES (Sora Font - Hero, large banners) ---
  static TextStyle get displayLarge => GoogleFonts.sora(
    fontSize: 57,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static TextStyle get displayMedium => GoogleFonts.sora(
    fontSize: 45,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.0,
    height: 1.15,
  );

  static TextStyle get displaySmall => GoogleFonts.sora(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.0,
    height: 1.20,
  );

  // --- HEADLINE STYLES (Sora Font - Screen titles) ---
  static TextStyle get headlineLarge => GoogleFonts.sora(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.0,
    height: 1.25,
  );

  static TextStyle get headlineMedium => GoogleFonts.sora(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.0,
    height: 1.29,
  );

  static TextStyle get headlineSmall => GoogleFonts.sora(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    height: 1.33,
  );

  // --- TITLE STYLES (Sora Font - App bars, sections, cards) ---
  static TextStyle get titleLarge => GoogleFonts.sora(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.0,
    height: 1.27,
  );

  static TextStyle get titleMedium => GoogleFonts.sora(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    height: 1.4,
  );

  static TextStyle get titleSmall => GoogleFonts.sora(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // --- BODY STYLES (Inter Font - Paragraphs, listings) ---
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // --- LABEL STYLES (Inter Font - Buttons, chips, small titles) ---
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // --- CAPTION STYLES (Inter Font - Metadata, secondary info) ---
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02,
    height: 1.33,
  );
}
