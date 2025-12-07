import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

class CategoryTileWidget extends StatelessWidget {
  final Function() onTap;
  final String image;
  final String text;
  final Widget? trailing;
  final IconData? icon;
  final String? assetIcon;
  const CategoryTileWidget({
    super.key,
    required this.onTap,
    required this.image,
    required this.text,
    this.trailing,
    this.icon,
    this.assetIcon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(children: [
          Row(children: [
            if (icon != null)
              Icon(
                icon,
                size: 24,
                color: const Color(0xFFFF0050),
              )
            else if (assetIcon != null)
              Image.asset(
                assetIcon!,
                width: 24,
                height: 24,
                color: const Color(0xFFFF0050),
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: AppColors.red,
                ),
              )
            else
              Image.network(
                image,
                width: 24,
                height: 24,
                color: const Color(0xFFFF0050),
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: AppColors.red,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ]),
        ]),
        Column(children: [
          trailing ??
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface,
                size: 26,
              ),
        ]),
      ]),
    );
  }
}
