import 'package:cherry_mvp/core/config/app_spacing.dart';
import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/password_flow/wigets/greeting_lable.dart';
import 'package:cherry_mvp/features/password_flow/wigets/hiddenpassoword_field.dart';
import 'package:flutter/material.dart';

class PasswordPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImages.password_home),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.large),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(AppImages.profileImg),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.large), // TODO: Get from config

                    // Greeting Label
                    GreetingLabel(initialName: 'Romaina'),

                    SizedBox(
                        height: AppSpacing.extraLarge), // TODO: Get from config

                    // Password Field
                    HiddenPasswordField(),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Row ("Not you" and Icon Button)
          Positioned(
            bottom: 20, // Distance from the bottom
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                //crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // "Not you" Text
                  Text(
                    'Not you',
                    style: AppTextStyles.bodyText,
                  ),

                  // Icon Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () {},
                    child: Icon(
                      Icons.arrow_forward,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
