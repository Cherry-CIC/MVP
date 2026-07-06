import 'package:flutter/material.dart';

class ProductHighlightTile extends StatelessWidget {
  final String leadingText;
  final String trailingText;
  final Widget trailingIcon;
  final VoidCallback? onTap;

  const ProductHighlightTile({
    super.key,
    required this.leadingText,
    required this.trailingText,
    required this.trailingIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
      child: Material(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        type: MaterialType.button,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.centerLeft,
                end: const Alignment(2, .5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      leadingText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      trailingText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    width: 32,
                    child: Center(child: trailingIcon),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}