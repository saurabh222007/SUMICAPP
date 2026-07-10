import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import '../shared/themes/app_theme.dart';

/// The root Widget of the SUMIC Application.
class SumicApp extends ConsumerWidget {
  const SumicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In later phases, we can listen to a ThemeProvider to toggle themeMode dynamically
    return MaterialApp.router(
      title: 'SUMIC',
      debugShowCheckedModeBanner: false,
      
      // Theme settings (Defaulting to Dark Mode)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      
      // Routing configuration
      routerConfig: appRouter,
    );
  }
}
