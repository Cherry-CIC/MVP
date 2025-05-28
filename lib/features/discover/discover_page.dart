// TODO Implement this library.

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_card.dart';
import 'package:flutter/material.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: EdgeInsets.all(18.0),
        child: DiscoverCharityCard(),
      ),
    );
  }
}
