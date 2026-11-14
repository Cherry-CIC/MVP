import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

class PickupPointsLoadingWidget extends StatelessWidget {
  const PickupPointsLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                AppStrings.loadingPickupPoint,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
