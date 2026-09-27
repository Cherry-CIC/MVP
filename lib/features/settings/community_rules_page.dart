import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/settings/legal_document_page.dart';
import 'package:flutter/material.dart';

class CommunityRulesPage extends StatelessWidget {
  const CommunityRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: AppStrings.communityRulesText,
      assetPath: 'assets/legal/community_rules.txt',
    );
  }
}
