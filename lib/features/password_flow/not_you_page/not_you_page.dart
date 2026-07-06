import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_spacing.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';

class NotYouPage extends StatelessWidget {
  const NotYouPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background Image
              Positioned(
                child: SizedBox(
                  height: double.infinity,
                  child: Image.asset(
                    AppImages.notYouHome,
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
                    bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.medium,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.2),

                      AspectRatio(
                        aspectRatio: 12 / 9,
                        child: Image.asset(
                          AppImages.cherryLogo,
                          fit: BoxFit.contain,
                        ),
                      ),

                      SizedBox(height: AppSpacing.large),

                      // First Text
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(AppStrings.userCheck, style: Theme.of(context).textTheme.headlineMedium),
                      ),
                      SizedBox(height: AppSpacing.medium),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(AppStrings.forgotPasswordInstruction),
                      ),
                      SizedBox(height: AppSpacing.large),
                      TextField(
                        decoration: InputDecoration(
                          hintText: AppStrings.email,
                        ),
                      ),
                      if (FeatureFlags.showDeferredControls) ...[
                        SizedBox(height: AppSpacing.large),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: OutlinedButton(
                            onPressed: () {},
                            child: const Text(AppStrings.sendEmail),
                          ),
                        ),
                      ],
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
