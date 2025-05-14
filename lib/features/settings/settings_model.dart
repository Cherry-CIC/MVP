import 'package:cherry_mvp/core/config/config.dart'; 
import 'package:cherry_mvp/core/models/model.dart'; 

const dummySettingsItems = [
  SectionSettings(
    header: AppStrings.support_Text, 
    list_items:[ 
      SectionSettingsItem(subheader: AppStrings.chat_with_us_Text, subheaderArrow: ''), 
      SectionSettingsItem(subheader: AppStrings.FAQ_Text, subheaderArrow: '')
    ] 
  ),

  SectionSettings(
    header: AppStrings.personal_Text, 
    list_items:[ 
      SectionSettingsItem(subheader: AppStrings.profile_Text, subheaderArrow: ''), 
      SectionSettingsItem(subheader: AppStrings.shipping_address_Text, subheaderArrow: ''),
      SectionSettingsItem(subheader: AppStrings.payment_methods_Text, subheaderArrow: ''),  
      SectionSettingsItem(subheader: AppStrings.postage_Text, subheaderArrow: '')
    ] 
  ),

  SectionSettings(
    header: AppStrings.shop_Text, 
    list_items:[
      SectionSettingsItem(subheader: AppStrings.country_Text, subheaderArrow: AppStrings.united_kingdom_Text),
      SectionSettingsItem(subheader: AppStrings.currency_Text, subheaderArrow: AppStrings.pound_Text), 
      SectionSettingsItem(subheader: AppStrings.sizes_Text, subheaderArrow: AppStrings.UK_Text)
    ] 
  ),

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