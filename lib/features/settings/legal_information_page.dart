import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/settings/community_rules_page.dart';
import 'package:cherry_mvp/features/settings/privacy_policy_page.dart';
import 'package:cherry_mvp/features/settings/terms_and_conditions_page.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_item.dart';
import 'package:flutter/material.dart';

class LegalInformationPage extends StatelessWidget {
  const LegalInformationPage({super.key});

  void _navigateToDocument(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(AppStrings.legalInformationText),
            floating: true,
            snap: true,
          ),
          SliverList.list(
            children: [
              const PrivacyPolicyLink(),
              const Divider(height: 1),
              SettingsItem(
                title: AppStrings.termsAndConditionsText,
                trailing: '',
                onTap: () => _navigateToDocument(context, const TermsAndConditionsPage()),
              ),
              const Divider(height: 1),
              SettingsItem(
                title: AppStrings.communityRulesText,
                trailing: '',
                onTap: () => _navigateToDocument(context, const CommunityRulesPage()),
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
          ),
        ],
      ),
    );
  }
}
