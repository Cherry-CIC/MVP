import 'package:flutter/material.dart';    
import 'package:cherry_mvp/core/config/config.dart'; 

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key, });  

  @override 
  Widget build(BuildContext context) {     

    return AppBar( 
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: Icon(
            Icons.reply, 
            color: AppColors.primary,  
          ),
          onPressed: () {},
        ), 
  
        title: Text(
          AppStrings.settings_Text,
          style: TextStyle(fontSize:15, color: AppColors.black, fontWeight: FontWeight.w800,), 
        ),     
 
        centerTitle: true,   
        
    ); 
  } 

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
