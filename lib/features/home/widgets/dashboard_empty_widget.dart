import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class DashboardEmptyWidget extends StatelessWidget {
  final String? categoryName;
  final VoidCallback? onResetCategory;

  const DashboardEmptyWidget({
    this.categoryName,
    this.onResetCategory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              categoryName == null
                  ? AppStrings.noProductsAvailable
                  : 'No items in $categoryName yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            if (categoryName != null && onResetCategory != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onResetCategory,
                child: const Text('Show all items'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
