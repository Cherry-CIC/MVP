import 'package:flutter/material.dart';

class UserOrderTile extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final String assetPath;
  final double iconSize;

  const UserOrderTile({
    super.key,
    required this.title,
    required this.onPressed,
    required this.assetPath,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Image.asset(
                assetPath,
                height: iconSize,
                width: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
