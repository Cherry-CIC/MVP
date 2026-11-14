import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/router/nav_provider.dart';
import '../../core/router/nav_routes.dart';

void _navigateToFaq(BuildContext context) {
  final navigator = Provider.of<NavigationProvider>(context, listen: false);
  navigator.navigateTo(AppRoutes.faqsPage);
}

void _navigateToLegalInformation(BuildContext context) {
  final navigator = Provider.of<NavigationProvider>(context, listen: false);
  navigator.navigateTo(AppRoutes.legalInformationPage);
}

class ContactSupportLink extends StatelessWidget {
  const ContactSupportLink({super.key});

  static final _url = Uri.parse(AppStrings.contactUrl);

  Future<void> _open(BuildContext context) async {
    try {
      if (await launchUrl(_url, mode: LaunchMode.externalApplication)) return;
    } on PlatformException {
      // Some platforms throw instead of reporting a failed launch.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText('Please open $_url in your browser.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 32, right: 16),
        title: Text(
          AppStrings.contactUrl,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => _open(context),
      ),
    );
  }
}

final dummyAccountSection = [
  if (FeatureFlags.showDeferredControls) ...[
    SectionSettingsItem(
      title: AppStrings.languageText,
      trailing: AppStrings.englishText,
    ),
    SectionSettingsItem(title: AppStrings.securityText, trailing: ''),
    SectionSettingsItem(title: AppStrings.aboutUsText, trailing: ''),
    SectionSettingsItem(title: AppStrings.cookieSettingsText, trailing: ''),
  ],
  SectionSettingsItem(
    title: AppStrings.legalInformationText,
    trailing: '',
    onTap: _navigateToLegalInformation,
  ),
  SectionSettingsItem(title: AppStrings.logOutText, trailing: ''),
];

final dummyShopSection = [
  if (FeatureFlags.showDeferredControls) ...[
    SectionSettingsItem(
      title: AppStrings.countryText,
      trailing: AppStrings.unitedKingdomText,
    ),
    SectionSettingsItem(
      title: AppStrings.currencyText,
      trailing: AppStrings.poundText,
    ),
    SectionSettingsItem(
      title: AppStrings.sizesText,
      trailing: AppStrings.ukText,
    ),
  ],
];

final dummySupportSection = [
  if (FeatureFlags.showDeferredControls) SectionSettingsItem(title: AppStrings.chatWithUsText, trailing: ''),
  SectionSettingsItem(
    title: AppStrings.faqText,
    trailing: '',
    onTap: _navigateToFaq,
  ),
  SectionSettingsItem(
    title: AppStrings.contactText,
    trailing: '',
    children: const [ContactSupportLink()],
  ),
];

final dummyPersonalSection = [
  if (FeatureFlags.showDeferredControls) ...[
    SectionSettingsItem(title: AppStrings.profilesText, trailing: ''),
    SectionSettingsItem(title: AppStrings.shippingAddressText, trailing: ''),
    SectionSettingsItem(title: AppStrings.paymentMethodsText, trailing: ''),
    SectionSettingsItem(title: AppStrings.postageText, trailing: ''),
  ],
];
