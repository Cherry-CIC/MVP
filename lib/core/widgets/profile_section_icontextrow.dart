import 'package:flutter/material.dart';

class IconTextRow extends StatelessWidget {
  final String assetPath;
  final String text;

  const IconTextRow({
    super.key,
    required this.assetPath,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              height: 16,
              width: 16,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
