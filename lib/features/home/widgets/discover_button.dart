import 'package:cherry_mvp/core/config/app_button_style.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:provider/provider.dart';

import '../../../core/router/nav_provider.dart';
import '../../../core/router/nav_routes.dart';

class DiscoverButton extends StatelessWidget {
  const DiscoverButton({super.key});


  void _navigate(BuildContext context) {
    final navigator = Provider.of<NavigationProvider>(context, listen: false);
    navigator.navigateTo(AppRoutes.discover);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: AppButtonStyle.exploreButtonStyle,
        onPressed: () => _navigate(context),
        child: Container(
          width: double.infinity,
          height: 152,
          child: Row ( children: [
            Expanded(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.exploreText,
                        style: AppTextStyles.exploreLargeText,
                      ),
                      Text(
                        AppStrings.discoverSomethingText,
                        style: AppTextStyles.exploreSmallText,
                      )
                    ],
                  )
                )
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(AppImages.explore_charities, height: 146)
              )
            )
            ]
          )
        ),
      );
  }
}
