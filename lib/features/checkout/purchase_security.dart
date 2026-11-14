import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';

class PurchaseSecurity extends StatelessWidget {
  const PurchaseSecurity({super.key});

  static const _sectionHeadingStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    final missionAccent = Theme.of(context).brightness == Brightness.dark
        ? AppColors.red
        : AppColors.primaryAction;
    return Scaffold(
      appBar: AppBar(leading: const CloseButton()),
      body: Container(
        padding: EdgeInsets.all(15),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Center(
                    child: Image.asset(
                      AppImages.checkoutPurchaseSecurityShield,
                      width: 114,
                      height: 126,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Center(
                    child: Text(
                      AppStrings.purchaseSecurityHeading,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      AppStrings.purchaseSecuritySubHeading,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 20,
                    children: [
                      Image.asset(
                        AppImages.refundPolicy,
                        width: 30,
                        height: 30,
                        excludeFromSemantics: true,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.refundPolicyHeading,
                              style: _sectionHeadingStyle,
                            ),
                            Text(AppStrings.refundPolicyConditionsHeading),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 5,
                              children: [
                                Text("\u2022", style: TextStyle(fontSize: 16, height: 1.5)),
                                Expanded(child: Text(AppStrings.refundPolicyConditionOne)),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 5,
                              children: [
                                Text("\u2022", style: TextStyle(fontSize: 16, height: 1.5)),
                                Expanded(child: Text(AppStrings.refundPolicyConditionTwo)),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 5,
                              children: [
                                Text("\u2022", style: TextStyle(fontSize: 16, height: 1.5)),
                                Expanded(child: Text(AppStrings.refundPolicyConditionThree)),
                              ],
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: AppStrings.refundPolicyBodyTextStart),
                                  TextSpan(
                                    text: AppStrings.refundPolicyBodyTextBold,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: AppStrings.refundPolicyBodyTextEnd),
                                ],
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: AppStrings.refundPolicyReturns),
                                  TextSpan(
                                    text: AppStrings.refundPolicyLinkText,
                                    style: TextStyle(decoration: TextDecoration.underline),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        AppImages.secureTransactions,
                        width: 30,
                        height: 30,
                        excludeFromSemantics: true,
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.secureTransactionsHeading,
                              style: _sectionHeadingStyle,
                            ),
                            Text(AppStrings.secureTransactionsBodyOne),
                            SizedBox(height: 15),
                            Text(AppStrings.secureTransactionsBodyTwo),
                            Text(
                              AppStrings.secureTransactionsBodyThreeBold,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        AppImages.yourSupport,
                        width: 30,
                        height: 30,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.yourSupportHeading,
                              style: _sectionHeadingStyle,
                            ),
                            Text(AppStrings.yourSupportBody),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        AppImages.supportOurMission,
                        width: 30,
                        height: 30,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.supportMissionHeading,
                              style: _sectionHeadingStyle.copyWith(color: missionAccent),
                            ),
                            const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: AppStrings.supportMissionBoldTextSpan,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: AppStrings.supportMissionNormalTextSpan,
                                  ),
                                ],
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: AppStrings.supportMissionPlainText,
                                  ),
                                  TextSpan(
                                    text: AppStrings.supportMissionPinkText,
                                    style: TextStyle(color: missionAccent),
                                  ),
                                ],
                              ),
                            ),
                            Text(AppStrings.supportMissionBodyText),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.purchaseSecurityButtonText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
