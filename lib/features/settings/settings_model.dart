import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/model.dart';

final dummyAccountSection = [
  SectionSettingsItem(
    title: AppStrings.languageText,
    trailing: AppStrings.englishText,
  ),
  SectionSettingsItem(title: AppStrings.securityText, trailing: ''),
  SectionSettingsItem(title: AppStrings.aboutUsText, trailing: ''),
  SectionSettingsItem(title: AppStrings.legalInformationText, trailing: ''),
  SectionSettingsItem(title: AppStrings.cookieSettingsText, trailing: ''),
  SectionSettingsItem(title: AppStrings.logOutText, trailing: ''),
];

final dummyShopSection = [
  SectionSettingsItem(
    title: AppStrings.countryText,
    trailing: AppStrings.unitedKingdomText,
  ),
  SectionSettingsItem(
    title: AppStrings.currencyText,
    trailing: AppStrings.poundText,
  ),
  SectionSettingsItem(title: AppStrings.sizesText, trailing: AppStrings.ukText),
];

final dummySupportSection = [
  SectionSettingsItem(title: AppStrings.chatWithUsText, trailing: ''),
  SectionSettingsItem(title: AppStrings.faqText, trailing: ''),
];

final dummyPersonalSection = [
  SectionSettingsItem(title: AppStrings.profilesText, trailing: ''),
  SectionSettingsItem(title: AppStrings.shippingAddressText, trailing: ''),
  SectionSettingsItem(title: AppStrings.paymentMethodsText, trailing: ''),
  SectionSettingsItem(title: AppStrings.postageText, trailing: ''),
];
