import 'dart:core';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class SettingsToggleSection extends StatelessWidget {
  const SettingsToggleSection({
    super.key,
    required this.isSwitchedDark,
    required this.toggleSwitchDark,
    required this.isSwitchedHide,
    required this.toggleSwitchHide,
  });

  final bool isSwitchedDark;
  final void Function(bool)? toggleSwitchDark;

  final bool isSwitchedHide;
  final void Function(bool)? toggleSwitchHide;

  @override
  Widget build(BuildContext context) {
    return SliverList.list(
      children: [
        SwitchListTile.adaptive(
          title: Text(AppStrings.darkModeText),
          value: isSwitchedDark,
          onChanged: toggleSwitchDark,
          inactiveThumbColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        if (FeatureFlags.showDeferredControls) ...[
          Divider(height: 1),
          SwitchListTile.adaptive(
            title: Text(AppStrings.listListingsText),
            value: isSwitchedHide,
            onChanged: toggleSwitchHide,
            inactiveThumbColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }
}
