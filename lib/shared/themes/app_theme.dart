import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_shapes.dart';
import 'app_typography.dart';

/// AppTheme configuration for the SUMIC application.
/// Provides ThemeData definitions for Light and Dark modes.
abstract class AppTheme {
  /// Defines the dark theme (the primary theme of SUMIC, suitable for a music streaming app).
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      
      // Color Scheme config using modern, non-deprecated Material 3 fields
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.black,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.tertiary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        error: AppColors.error,
        onError: AppColors.onError,
      ),

      // Text Theme mapping
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.darkOnSurface),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.darkOnSurface),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.darkOnSurface),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.darkOnSurface),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.darkOnSurface),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.darkOnSurface),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.darkOnSurface),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.darkOnSurface),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.darkOnSurface),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkOnBackground),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnBackground),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.darkOnSurfaceVariant),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.darkOnSurface),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.darkOnSurfaceVariant),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.darkOnSurfaceVariant),
      ),

      // Component Themes configuration
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: AppShapes.eL1,
        shape: AppShapes.shapeMd,
        clipBehavior: Clip.antiAlias,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          elevation: AppShapes.eL1,
          shape: AppShapes.shapePill,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppShapes.radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.radiusMd,
          borderSide: const BorderSide(color: AppColors.darkSurfaceVariant, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.radiusMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShapes.radiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnSurfaceVariant),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnSurfaceVariant),
      ),
    );
  }

  /// Defines the light theme fallback.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.tertiary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        error: AppColors.error,
        onError: AppColors.onError,
      ),

      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.lightOnSurface),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.lightOnSurface),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.lightOnSurface),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.lightOnSurface),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.lightOnSurface),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.lightOnSurface),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.lightOnSurface),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.lightOnSurface),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.lightOnSurface),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.lightOnBackground),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.lightOnBackground),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.lightOnSurfaceVariant),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.lightOnSurface),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.lightOnSurfaceVariant),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.lightOnSurfaceVariant),
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: AppShapes.eL1,
        shape: AppShapes.shapeMd,
        clipBehavior: Clip.antiAlias,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: AppShapes.eL1,
          shape: AppShapes.shapePill,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppShapes.radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.radiusMd,
          borderSide: const BorderSide(color: AppColors.lightSurfaceVariant, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.radiusMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShapes.radiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightOnSurfaceVariant),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightOnSurfaceVariant),
      ),
    );
  }
}
