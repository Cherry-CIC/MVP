import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(colorSpace: ColorSpace.sRGB),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }
}
