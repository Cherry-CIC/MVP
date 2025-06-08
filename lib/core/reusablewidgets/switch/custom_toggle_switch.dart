import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class CustomToggleSwitch extends StatelessWidget {
  final bool value;
  final void Function(bool)? onChanged;

  const CustomToggleSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      inactiveTrackColor: AppColors.greyTextColor, 
      activeColor: AppColors.primary, 
    );
  }
}