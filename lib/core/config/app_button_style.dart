import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppButtonStyle {
  static ButtonStyle buttonStyle1 = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary, // background
      foregroundColor: AppColors.lavenderBgColor,
      textStyle: AppTextStyles.buttonText1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(width: 2, color: AppColors.primary),
      )
      // foreground
      );
}
