import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/settings/settings_model.dart';

final dummyAccountSection = [
  SectionSettingsItem(
      title: AppStrings.language_Text, trailing: AppStrings.english_Text),
  SectionSettingsItem(title: AppStrings.security_Text, trailing: ''),
  SectionSettingsItem(title: AppStrings.about_us_Text, trailing: ''),
  SectionSettingsItem(title: AppStrings.legal_information_Text, trailing: ''),
  SectionSettingsItem(title: AppStrings.cookie_settings_Text, trailing: ''),
  SectionSettingsItem(title: AppStrings.log_out_Text, trailing: '')
];

final dummyShopSection = [
  SectionSettingsItem(
      title: AppStrings.country_Text, trailing: AppStrings.united_kingdom_Text),
  SectionSettingsItem(
      title: AppStrings.currency_Text, trailing: AppStrings.pound_Text),
  SectionSettingsItem(
      title: AppStrings.sizes_Text, trailing: AppStrings.UK_Text)
];

class UKText {
}

final dummySupportSection = [
  SectionSettingsItem(title: AppStrings.chat_with_us_Text, trailing: ''),
  SectionSettingsItem(title: AppStrings.FAQ_Text, trailing: '')
];

class FAQText {}

final dummyPersonalSection = [
  SectionSettingsItem(title: AppStrings.profilesText ?? '', trailing: ''),
  SectionSettingsItem(title: AppStrings.shipping_address_Text, trailing: ''),
  SectionSettingsItem(title: AppStrings.payment_methods_Text, trailing: ''),
  SectionSettingsItem(title: AppStrings.postage_Text, trailing: '')
];
