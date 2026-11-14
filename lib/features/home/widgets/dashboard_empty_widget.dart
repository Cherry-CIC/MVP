import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class DashboardEmptyWidget extends StatelessWidget {
  const DashboardEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noProductsAvailable,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
