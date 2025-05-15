import 'package:flutter/material.dart';    
import 'package:cherry_mvp/core/config/config.dart'; 
import 'package:cherry_mvp/core/utils/utils.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key, });  

  @override 
  Widget build(BuildContext context) {     

    return buildCommonAppBar(AppStrings.settings_Text, (){}); 
  } 

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
