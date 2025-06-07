import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/reusablewidgets/appbar/app_bar.dart';

class DiscoverHeader extends StatelessWidget implements PreferredSizeWidget {
  const DiscoverHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return buildCommonAppBarWithBackButton(
      "Discover Charities",
          () => Navigator.of(context).pop(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}