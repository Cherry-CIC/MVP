import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/settings/settings_model.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_category_group.dart';

class SettingsPersonal extends StatelessWidget {
  const SettingsPersonal({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCategoryGroup(
      children: dummyPersonalSection,
      heading: AppStrings.personalText,
    );
  }
}
