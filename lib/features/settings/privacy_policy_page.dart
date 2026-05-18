import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/settings/legal_document_page.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: AppStrings.privacyPolicyText,
      assetPath: 'assets/legal/privacy_policy.txt',
    );
  }
}
