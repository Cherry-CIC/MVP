import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  final String semanticsLabel;

  const LoadingView({super.key, this.semanticsLabel = AppStrings.loading});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
          semanticsLabel: semanticsLabel,
        ),
      ),
    );
  }
}
