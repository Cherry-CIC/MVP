import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final String imagetext;
  final Color color;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.imagetext,
    required this.onPressed,
    this.color = AppColors.black,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: AppColors.greyNavFooter, width: 2.0),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        minimumSize: const Size.fromHeight(50),
        foregroundColor: color,
      ),
      onPressed: onPressed,
      icon: Image.asset(
        imagetext,
        height: 24,
        width: 20,
      ),
      label: Text(
        label,
        style: AppTextStyles.signupCardButtonText,
      ),
    );
  }
}
