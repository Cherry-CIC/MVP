import 'package:cherry_mvp/core/config/config.dart';
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
          SliverList.separated(
            itemCount: _legalDocuments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _legalDocuments[index];
              return SettingsItem(
                title: item.title,
                trailing: '',
                onTap: () => _navigateToDocument(context, item.page),
              );
            },
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

class _LegalDocumentItem {
  const _LegalDocumentItem({
    required this.title,
    required this.page,
  });

  final String title;
  final Widget page;
}

const _legalDocuments = [
  _LegalDocumentItem(
    title: AppStrings.privacyPolicyText,
    page: PrivacyPolicyPage(),
  ),
  _LegalDocumentItem(
    title: AppStrings.termsAndConditionsText,
    page: TermsAndConditionsPage(),
  ),
];
