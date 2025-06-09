import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/settings/settings_model.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_category_group.dart';

class SettingsSupport extends StatelessWidget {
  const SettingsSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCategoryGroup(
  list_items: dummySupportSection,
  heading: AppStrings.support_Text,
);
// removed return Container() as it was not needed
  // The SettingsCategoryGroup widget is sufficient to display the support section
  }
}
