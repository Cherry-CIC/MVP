import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class DashboardLoadingWidget extends StatelessWidget {
  const DashboardLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Semantics(
          liveRegion: true,
          child: Column(
            children: [
              const ExcludeSemantics(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.loadingProducts,
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
