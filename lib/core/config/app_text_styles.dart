import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle heading1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static TextStyle buttonText1 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  // Body Text
  static TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.greyTextColor,
  );
  
  //profile page
  static TextStyle screen_title = TextStyle(
      fontSize: 24, color: AppColors.black, fontWeight: FontWeight.w600);
  static TextStyle bodyText_profile_heading = TextStyle(
      fontSize: 24,
      color: AppColors.greyTextColorTwo,
      fontWeight: FontWeight.w600);
  static TextStyle bodyText_profile_heading2 = TextStyle(
      fontSize: 16,
      color: AppColors.greyTextColorTwo,
      fontWeight: FontWeight.w600);
  static TextStyle bodyText_profile_subheading = TextStyle(
      fontSize: 13,
      color: AppColors.greyTextColor,
      fontWeight: FontWeight.w400);
}
