import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LegalInformationPage extends StatelessWidget {
  const LegalInformationPage({super.key});

  /// Opens a legal document through the shared named-route navigator.
  void _navigateToDocument(BuildContext context, String routeName) {
    final navigator = Provider.of<NavigationProvider>(context, listen: false);
    navigator.navigateTo(routeName);
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
                onTap: () => _navigateToDocument(context, item.routeName),
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
    required this.routeName,
  });

  final String title;

  /// Named route registered in [AppRoutes.generateRoute].
  final String routeName;
}

const _legalDocuments = [
  _LegalDocumentItem(
    title: AppStrings.privacyPolicyText,
    routeName: AppRoutes.privacyPolicyPage,
  ),
  _LegalDocumentItem(
    title: AppStrings.termsAndConditionsText,
    routeName: AppRoutes.termsAndConditionsPage,
  ),
  _LegalDocumentItem(
    title: AppStrings.communityRulesText,
    routeName: AppRoutes.communityRulesPage,
  ),
];