import 'package:cherry_mvp/core/config/app_button_style.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_input_decorations.dart';
import 'package:cherry_mvp/core/config/app_spacing.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:flutter/material.dart';

class NotYouPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background Image
              Positioned(
                child: Container(
                  height: double.infinity,
                  child: Image.asset(
                    AppImages.not_you_home,
                    fit: BoxFit.fill,
                  ),
                ),
              ),

              // Scrollable Content
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.medium,
                    right: AppSpacing.medium,
                    bottom: MediaQuery.of(context).viewInsets.bottom +
                        AppSpacing.medium,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.2),

                      AspectRatio(
                        aspectRatio: 12 / 9,
                        child: Image.asset(
                          AppImages.cherry_logo,
                          fit: BoxFit.contain,
                        ),
                      ),

                      SizedBox(height: AppSpacing.large),

                      // First Text
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppStrings.userCheck,
                          style: AppTextStyles.heading1,
                        ),
                      ),

                      SizedBox(height: AppSpacing.medium),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppStrings.forgotPassWordInstruction,
                          style: AppTextStyles.bodyText,
                        ),
                      ),

                      SizedBox(height: AppSpacing.large),

                      TextField(
                        decoration: AppInputDecorations
                            .inputDecorationWithBorderRadius1(
                          hintText: AppStrings.email,
                        ),
                      ),

                      SizedBox(height: AppSpacing.large),

                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: AppButtonStyle.buttonStyle1,
                          child: const Text(AppStrings.sendEmail),
                        ),
                      ),

                      SizedBox(height: AppSpacing.large),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
