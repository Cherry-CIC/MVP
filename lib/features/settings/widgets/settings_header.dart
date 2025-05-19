import 'package:flutter/material.dart';     
import 'package:cherry_mvp/core/config/config.dart'; 
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';

class SettingsHeader extends StatelessWidget implements PreferredSizeWidget {
  const SettingsHeader({super.key, });  
  
  @override  
  Widget build(BuildContext context) {     

    return buildCommonAppBar(AppStrings.settingsText, (){});
  } 

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
