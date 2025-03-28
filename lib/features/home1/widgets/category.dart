import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/model.dart';

class SingleCategory extends StatelessWidget {
  const SingleCategory({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          children: [
            // Adjust the height of the GridView to fit within the container
            SizedBox(
              height: 180, // Reduced height for the grid
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ), 
                itemCount: category.images.length,
                shrinkWrap:
                    true, // Ensures the GridView takes only necessary space
                physics: NeverScrollableScrollPhysics(), // Disable scrolling
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      category.images[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            // Add some spacing between the grid and the text
            SizedBox(height: 6),
            Row(
              children: [
                Text(
                  category.name,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.all(6), // Adjusted padding
                  decoration: BoxDecoration(
                    color: AppColors.lavenderBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category.number.toString(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
