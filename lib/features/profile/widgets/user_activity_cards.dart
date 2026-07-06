import 'package:flutter/material.dart';

class UserActivityCards extends StatelessWidget {
  final String title;
  final String value;

  const UserActivityCards({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 8,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
