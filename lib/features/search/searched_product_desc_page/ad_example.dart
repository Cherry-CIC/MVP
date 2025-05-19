import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class AdExample extends StatelessWidget {
  const AdExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16), // Adjust padding as needed
            child: Text(
              AppStrings.adText,
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
