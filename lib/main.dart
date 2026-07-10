import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/services/logger_service.dart';

void main() async {
  try {
    // 1. Run bootstrap routines
    final ProviderContainer container = await AppBootstrap.bootstrap();

    // 2. Launch the application inside the provider scope
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const SumicApp(),
      ),
    );
  } catch (e, stackTrace) {
    AppLogger.e('Fatal crash during app initialization', e, stackTrace);
    
    // Fallback UI to show when bootstrapping crashes completely
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F0F13),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'A fatal error occurred during initialization:\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
