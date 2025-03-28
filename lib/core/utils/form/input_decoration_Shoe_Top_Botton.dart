import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

InputDecoration buildInputDecorationShoeTopBottom({required String labelText, required String hintText, IconData? icon, double? enabledBorderRadiusValue, Color? iconColor}) {
  return InputDecoration(  
    labelText: labelText, // Label above the TextField
    hintText: hintText, // Placeholder inside the TextField 
    labelStyle: TextStyle(color: AppColors.greyTextColor, fontSize: 18), // Styling the label
    hintStyle: TextStyle(color: AppColors.greyTextColor, fontSize: 16), // Styling the placeholder
    border: OutlineInputBorder( // Adds a border around the TextField
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: AppColors.primary),
    ),
    focusedBorder: OutlineInputBorder(
      // borderRadius: BorderRadius.circular(10.0),
      borderRadius: BorderRadius.circular(enabledBorderRadiusValue != null ? enabledBorderRadiusValue : 10.0),
      borderSide: BorderSide(color: AppColors.primary, width: 2.0),
    ),
    enabledBorder: OutlineInputBorder(
      // borderRadius: BorderRadius.circular(10.0),
      borderRadius: BorderRadius.circular(enabledBorderRadiusValue != null ? enabledBorderRadiusValue : 10.0),
      borderSide: BorderSide(color: AppColors.transparent), 
    ),  
    suffixIcon: icon != null ? Icon(
      icon, 
      color: iconColor != null ? iconColor : AppColors.greyTextColor
    ): null,
    filled: true,
    fillColor: Colors.grey[100], // Background color
  );
}