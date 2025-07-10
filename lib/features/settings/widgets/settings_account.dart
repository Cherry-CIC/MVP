import 'dart:core';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/settings/settings_model.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_category_group.dart';

class SettingsAccount extends StatelessWidget {
  const SettingsAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SettingsCategoryGroup(
          list_items: dummyAccountSection, heading: AppStrings.account_Text),
    );
  }
}
