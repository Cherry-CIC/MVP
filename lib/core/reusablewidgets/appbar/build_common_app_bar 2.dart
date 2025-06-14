import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

PreferredSizeWidget buildCommonAppBar(
    String title, VoidCallback onBackPressed) {
  return AppBar(
    backgroundColor: AppColors.white,
    leading: IconButton(
      icon: Icon(
        Icons.reply,
        color: AppColors.primary,
      ),
      onPressed: onBackPressed,
    ),
    title: Text(
      title,
      style: TextStyle(
        fontSize: 15,
        color: AppColors.black,
        fontWeight: FontWeight.w800,
      ),
    ),
    centerTitle: true,
  );
}
