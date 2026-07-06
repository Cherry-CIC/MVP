import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class CategoryLoadingWidget extends StatelessWidget {
  const CategoryLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              AppStrings.loadingCategories,
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
