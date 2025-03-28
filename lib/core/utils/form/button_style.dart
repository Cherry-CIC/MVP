import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

ButtonStyle elevatedButtonStyle(BuildContext context) {
  return ElevatedButton.styleFrom(  
    backgroundColor: AppColors.primary, // Background color
    foregroundColor: AppColors.white, // Text color
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10), // Rounded corners
    ),
    textStyle: Theme.of(context).textTheme.bodySmall,
  );
}
