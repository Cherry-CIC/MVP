import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

class PrimaryAppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttonText;
  final double? width;
  final double? height;
  final TextStyle? textStyle; // ✅ Make it a field

  const PrimaryAppButton({
    super.key,
    required this.onPressed,
    required this.buttonText,
    this.width,
    this.height,
    this.textStyle, // ✅ Now optional
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? AppMeasurements.getScreenWidth(context),
      height: height ?? 45,
      child: ElevatedButton(
        onPressed: onPressed,
        style: elevatedButtonStyle(context),
        child: Text(
          buttonText,
          style: textStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}
