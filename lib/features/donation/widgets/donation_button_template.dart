import 'package:flutter/material.dart'; 
import 'package:cherry_mvp/core/utils/utils.dart';

class DonationButtonTemplate extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttonText; 
  final Color backgroundColor;
  final Color foregroundColor; 
  final Color borderSideColor; 

  const DonationButtonTemplate({
    super.key,
    required this.onPressed,
    required this.buttonText, 
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderSideColor 
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height:45,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,  
            foregroundColor: foregroundColor,   // text color
            side: BorderSide(color: borderSideColor, width: 2),  
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),  

          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0), 
            child: Text(
              buttonText,
              style: TextStyle(fontWeight: FontWeight.w800)
            ),
          )
        ),
      ), 
    );
  }
}