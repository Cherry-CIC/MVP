import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.only(top: 15.0),
        child: CupertinoSwitch(
          value: isSwitchedDark,
          onChanged: toggleSwitchDark,
          inactiveTrackColor: AppColors.greyTextColor,
          activeTrackColor: AppColors.primary,
        ),
      ),
      Text(
        AppStrings.darkModeText,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.greyTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: 5.0),
        child: CupertinoSwitch(
          value: isSwitchedHide,
          onChanged: toggleSwitchHide,
          inactiveTrackColor: AppColors.greyTextColor,
          activeTrackColor: AppColors.primary,
        ),
      ),
      Text(
        AppStrings.listListingsText,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.greyTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);
  }
}
