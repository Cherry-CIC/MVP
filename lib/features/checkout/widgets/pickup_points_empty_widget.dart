import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

class PickupPointsEmptyWidget extends StatelessWidget {
  const PickupPointsEmptyWidget({super.key});

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
              ExcludeSemantics(
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.noPickupPointAvailable,
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
