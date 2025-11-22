import 'dart:ui';
import 'package:flutter/material.dart';
typedef ItemTapCallback = void Function(BuildContext context);
class SectionSettingsItem {
  final String title;
  final String trailing;
  final ItemTapCallback? onTap;

  const SectionSettingsItem(
  {
    this.onTap,
    required this.title,
    required this.trailing,
  });
}
