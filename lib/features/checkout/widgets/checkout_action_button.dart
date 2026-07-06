import 'package:flutter/material.dart';

class CheckoutActionButton extends StatelessWidget {
  final Widget label;
  final Widget? icon;
  final VoidCallback? onPressed;

  const CheckoutActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Stack(
            children: [
              Positioned(
                top: 12,
                left: 12,
                right: 24,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  child: label,
                ),
              ),
              if (icon != null)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: icon!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
