import 'dart:core';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class ToggleSection extends StatelessWidget {
  const ToggleSection({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 15.0),
          child: Switch.adaptive(
            value: isSwitchedDark,
            onChanged: toggleSwitchDark,
            inactiveTrackColor: Theme.of(context).colorScheme.onSurfaceVariant,
            activeTrackColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          AppStrings.darkModeText,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (FeatureFlags.showDeferredControls) ...[
          Padding(
            padding: EdgeInsets.only(top: 5.0),
            child: Switch.adaptive(
              value: isSwitchedHide,
              onChanged: toggleSwitchHide,
              inactiveTrackColor: Theme.of(context).colorScheme.onSurfaceVariant,
              activeTrackColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            AppStrings.listListingsText,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
