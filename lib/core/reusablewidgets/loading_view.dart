import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      //no need for container with white background
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }
}
