import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class EmptyStateCard extends StatelessWidget {
  final String message;

  const EmptyStateCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            width: double.infinity,
            AppImages.emptyStateBg,
            fit: BoxFit.cover,
          ),
          Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
