import 'package:flutter/material.dart';

/// Centralized color palette for the SUMIC application.
/// Derived directly from the premium Stitch design tokens.
abstract class AppColors {
  // --- BRAND COLORS (Premium Violet & Indigo) ---
  static const Color primary = Color(0xFF7C4DFF);      // Deep Violet (Main Accent)
  static const Color primaryLight = Color(0xFFB39DDB); // Lavender
  static const Color primaryContainer = Color(0xFF6750A4); // Deep Purple Container
  static const Color onPrimaryContainer = Color(0xFFE0D2FF);
  static const Color primaryPurpleLight = Color(0xFFCFBCFF);
  
  // Gradients for glassmorphism and primary buttons
  static const Color gradientStart = Color(0xFF7C4DFF); // Purple
  static const Color gradientEnd = Color(0xFFFF5C8A);   // Rose/Pink
  
  static const Color secondary = Color(0xFFCDC0E9);    // Secondary
  static const Color secondaryContainer = Color(0xFF4D4465);
  static const Color onSecondaryContainer = Color(0xFFBFB2DA);
  
  static const Color tertiary = Color(0xFFE7C365);     // Soft Gold / Amber Highlight
  static const Color tertiaryContainer = Color(0xFFC9A74D);

  // --- NEUTRALS (Dark Mode - Primary Mode for Music Apps) ---
  static const Color darkBackground = Color(0xFF0D0D12);      // Deep Midnight Void
  static const Color darkSurface = Color(0xFF141218);         // Base Surface
  static const Color darkSurfaceContainerLow = Color(0xFF1D1B20);
  static const Color darkSurfaceContainer = Color(0xFF211F24);
  static const Color darkSurfaceContainerHigh = Color(0xFF2B292F);
  static const Color darkSurfaceContainerHighest = Color(0xFF36343A);
  static const Color darkSurfaceVariant = Color(0xFF36343A);  // Card Borders / Dividers
  static const Color darkOnBackground = Color(0xFFE6E0E9);
  static const Color darkOnSurface = Color(0xFFE6E0E9);
  static const Color darkOnSurfaceVariant = Color(0xFFCBC4D2); // Muted subtitles
  static const Color darkOutline = Color(0xFF948E9C);

  // --- NEUTRALS (Light Mode Fallback) ---
  static const Color lightBackground = Color(0xFFF9F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F0F4);
  static const Color lightOnBackground = Color(0xFF1A1A1E);
  static const Color lightOnSurface = Color(0xFF1A1A1E);
  static const Color lightOnSurfaceVariant = Color(0xFF5A5A65);

  // --- SEMANTIC COLORS (Status Indications) ---
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color warning = Color(0xFFF1C21B);
  static const Color onWarning = Color(0xFF1A1A1E);

  static const Color success = Color(0xFF24A148);
  static const Color onSuccess = Color(0xFFFFFFFF);

  // --- EXTRA OVERLAYS ---
  static const Color overlayBlack30 = Color(0x4D000000);
  static const Color overlayBlack60 = Color(0x99000000);
  static const Color overlayWhite10 = Color(0x1AFFFFFF);
  static const Color overlayWhite20 = Color(0x33FFFFFF);
  static const Color overlayWhite5 = Color(0x0DFFFFFF);
}
