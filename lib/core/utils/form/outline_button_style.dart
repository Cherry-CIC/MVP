import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

ButtonStyle elevatedOutlineButtonStyle(BuildContext context) {
  return ElevatedButton.styleFrom(
    backgroundColor: AppColors.white, // Background color
    foregroundColor: AppColors.primary, // text color
    side: BorderSide(color: AppColors.primary, width: 2),  
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0), // Rounded corners
    ),
    textStyle: Theme.of(context).textTheme.bodySmall,
  );
}
 