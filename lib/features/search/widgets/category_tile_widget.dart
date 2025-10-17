import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

class CategoryTileWidget extends StatelessWidget {
  final Function() onTap;
  final String image;
  final String text;
  final Widget? trailing;
  const CategoryTileWidget({
    super.key,
    required this.onTap,
    required this.image,
    required this.text,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(children: [
          Row(children: [
            Image.network(
              image,
              width: 30,
              height: 30,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image,
                color: AppColors.red,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text(text, style: Theme.of(context).textTheme.titleSmall),
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
