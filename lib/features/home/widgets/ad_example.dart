import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class AdExample extends StatelessWidget {
  const AdExample({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(AppStrings.adText, style: Theme.of(context).textTheme.titleMedium),
          Image.asset(
            AppImages.adImage,
            width: screenWidth,
            fit: BoxFit.cover,
            cacheWidth: (screenWidth * MediaQuery.devicePixelRatioOf(context)).round(),
          ),
        ],
      ),
    );
  }
}
