import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final String buttonImage;
  final String buttonText;
  final double? width;
  final double? height;

  const SocialLoginButton({
    super.key,
    required this.onPressed,
    required this.backgroundColor,
    required this.buttonImage,
    required this.buttonText,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ??
          AppMeasurements.getScreenWidth(
              context), // Default to full screen width if not provided
      height: height ?? 45, // Default height if not provided
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Center(
              child: Image.asset(
                buttonImage,
                fit: BoxFit.contain,
                height: 25,
                width: 25,
              ),
            )),
        style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        label: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            buttonText,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
