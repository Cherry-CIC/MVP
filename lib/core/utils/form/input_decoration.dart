import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

InputDecoration buildInputDecoration({required String hintText, IconData? icon}) {
  return InputDecoration(
      filled: true,
      fillColor: AppColors.white,
      border:  const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.textFormOutline, width: 1.5),
      ),
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.black),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.black) : null,
      errorMaxLines: 3
  );
}