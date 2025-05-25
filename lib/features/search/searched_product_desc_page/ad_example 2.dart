import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class AdExample extends StatelessWidget {
  const AdExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              AppStrings.adText ?? '',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Image.asset(AppImages.ad_image),
        ],
      ),
    );
  }
}
