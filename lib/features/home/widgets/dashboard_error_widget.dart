import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class DashboardErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const DashboardErrorWidget({
    super.key,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Semantics(
          liveRegion: true,
          child: Column(
            children: [
              const ExcludeSemantics(
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.failedToLoadProducts,
                style: TextStyle(
                  fontSize: 16,
                  color: onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? AppStrings.unknownErrorOccurred,
                style: TextStyle(
                  fontSize: 14,
                  color: onSurfaceVariant,
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
