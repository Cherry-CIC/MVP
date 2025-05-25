import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final double height;
  final double width;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double border_radius;

  const CustomButton(
      {Key? key,
      required this.title,
      required this.onPressed,
      this.height = 60,
      this.width = double.infinity,
      this.backgroundColor = AppColors.piechart_red,
      this.borderColor = Colors.transparent,
      this.border_radius = 25,
      this.textColor = AppColors.white})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(border_radius),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
