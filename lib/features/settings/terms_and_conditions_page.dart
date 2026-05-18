import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/settings/legal_document_page.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: AppStrings.termsAndConditionsText,
      assetPath: 'assets/legal/terms_and_conditions.txt',
    );
  }
}
