import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_typography.dart';

class ErrorStateWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;

  const ErrorStateWidget({
    super.key,
    required this.onRetry,
    this.message = 'Something went wrong.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: Colors.black),
            label: const Text('Retry', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
