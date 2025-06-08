import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

class PrimaryAppOutlineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttonText;
  final double? width;
  final double? height;
 
  const PrimaryAppOutlineButton({
    super.key,
    required this.onPressed,
    required this.buttonText,
    this.width,
    this.height, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? AppMeasurements.getScreenWidth(context), // Default to full screen width if not provided
      height: height ?? 45, // Default height if not provided
      child: ElevatedButton(
        onPressed: onPressed,
        style: elevatedOutlineButtonStyle(context),
        child: Text(buttonText),
      ),
    );
  }
}