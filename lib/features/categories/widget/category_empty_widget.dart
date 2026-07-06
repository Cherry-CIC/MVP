import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class CategoryEmptyWidget extends StatelessWidget {
  const CategoryEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              AppStrings.noCategoriesAvailable,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
