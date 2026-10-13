import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final Color? color;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        minimumSize: const Size.fromHeight(50),
        foregroundColor: effectiveColor,
      ),
      onPressed: onPressed,
      icon: Image.asset(
        iconAsset,
        height: 24,
        width: 20,
      ),
      label: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: effectiveColor,
            ),
      ),
    );
  }
}
