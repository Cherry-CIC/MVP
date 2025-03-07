import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

class AppInputDecorations {
  static InputDecoration inputDecorationWithBorderRadius1({String? hintText}) {
    return InputDecoration(
        fillColor: AppColors.lightGreyFill,
        filled: true,
        hintText: hintText,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.0),
          borderSide: BorderSide(
              color: AppColors.lightGreyFill), // Customize focused border color
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.lightGreyFill),
          borderRadius: BorderRadius.circular(40.0),
        ));
  }
}
