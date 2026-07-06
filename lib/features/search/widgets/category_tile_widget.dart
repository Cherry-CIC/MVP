import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Row(
                children: [
                  Image.network(
                    image,
                    width: 24,
                    height: 24,
                    color: const Color(0xFFFF0050),
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      AppImages.getCategoryIcon(text),
                      width: 24,
                      height: 24,
                      color: const Color(0xFFFF0050),
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ?trailing,
        ],
      ),
    );
  }
}
