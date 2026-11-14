import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class PickupPointErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;
  const PickupPointErrorWidget(
      {super.key, this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              const ExcludeSemantics(
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.primaryAction,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.failedToLoadPickupPoint,
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? AppStrings.unknownErrorOccurred,
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
