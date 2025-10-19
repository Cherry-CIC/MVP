import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';

class PurchaseSecurity extends StatelessWidget {
  const PurchaseSecurity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
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
                      AppImages.checkoutPurhaseSecurityShield,
                      width: 114,
                      height: 126,
                    ),
                  ),
                  Center(
                    child: Text(
                      AppStrings.purchaseSecurityHeading,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      AppStrings.purchaseSecuritySubHeading,
                      style: TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(
                        AppImages.refundPolicy,
                        width: 30,
                        height: 30,
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.refundPolicyHeading,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(AppStrings.refundPolicyConditionsHeading),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "\u2022",
                                  style: TextStyle(fontSize: 16, height: 1.5),
                                ),
                                SizedBox(width: 5),
                                Text(AppStrings.refundPolicyConditionOne),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "\u2022",
                                  style: TextStyle(fontSize: 16, height: 1.5),
                                ),
                                SizedBox(width: 5),
                                Text(AppStrings.refundPolicyConditionTwo),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "\u2022",
                                  style: TextStyle(fontSize: 16, height: 1.5),
                                ),
                                SizedBox(width: 5),
                                Text(AppStrings.refundPolicyConditionThree),
                              ],
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: AppStrings.refundPolicyBodyTextStart,
                                  ),
                                  TextSpan(
                                    text: AppStrings.refundPolicyBodyTextBold,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: AppStrings.refundPolicyBodyTextEnd,
                                  ),
                                ],
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: AppStrings.refundPolicyReturns,
                                  ),
                                  TextSpan(
                                    text: AppStrings.refundPolicyLinkText,
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                    ),
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
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.secureTransactionsHeading,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
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
                      Image.asset(AppImages.yourSupport, width: 30, height: 30),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.yourSupportHeading,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(AppStrings.yourSupportBody),
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
                        AppImages.supportOurMission,
                        width: 30,
                        height: 30,
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.supportMissionHeading,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.red,
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: AppStrings.supportMissionBoldTextSpan,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        AppStrings.supportMissionNormalTextSpan,
                                  ),
                                ],
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: AppStrings.supportMissionPlainText,
                                  ),
                                  TextSpan(
                                    text: AppStrings.supportMissionPinkText,
                                    style: TextStyle(color: AppColors.red),
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
