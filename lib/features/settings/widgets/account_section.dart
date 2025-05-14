import 'package:flutter/material.dart';   
import 'package:cherry_mvp/core/config/config.dart'; 
import 'package:cherry_mvp/core/models/model.dart';  

import 'package:cherry_mvp/features/settings/widgets/category.dart';


const dummySettingsItems = [
  SectionSettings(
    header: AppStrings.account_Text, 
    list_items:[
      SectionSettingsItem(subheader: AppStrings.language_Text, subheaderArrow: AppStrings.english_Text),
      SectionSettingsItem(subheader: AppStrings.security_Text, subheaderArrow: ''),
      SectionSettingsItem(subheader: AppStrings.about_us_Text, subheaderArrow: ''),
      SectionSettingsItem(subheader: AppStrings.legal_information_Text, subheaderArrow: ''),
      SectionSettingsItem(subheader: AppStrings.cookie_settings_Text, subheaderArrow: ''),
      SectionSettingsItem(subheader: AppStrings.log_out_Text, subheaderArrow: '')
    ] 
  ),
  
]; 

class AccountSection extends StatelessWidget {
  const AccountSection({super.key});  

  @override 
  Widget build(BuildContext context) {     

    return Container( 
      child: SingleCategory(product: dummySettingsItems[0]),
    ); 
  } 
}
