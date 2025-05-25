import 'package:flutter/material.dart';   
import 'package:cherry_mvp/core/config/config.dart'; 
 
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.text, required this.iconPath,});

  final String text;
  final String iconPath;
 

  @override
  Widget build(BuildContext context) {  

    return Row(
      children: [
        Image.asset(
          iconPath,
          height: 16,
          width: 16,
        ), 

        Padding(
          padding: EdgeInsets.only(left:8.0), 
          child: Text(
            "${text}",
            style: AppTextStyles.bodyText_profile_subheading
          )
        ),
        
        
      ],
    );
  }
}
