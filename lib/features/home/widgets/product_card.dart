import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/model.dart';

class SingleProduct extends StatelessWidget {
  const SingleProduct({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Aligns children to the left
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  product.product_image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 28,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.greenBgColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    product.number.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: ClipRRect(borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                product.charity_image,
                width: 45,
                height: 40,
              ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(5, 3, 8, 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Row(
                  children: [
                    Image.asset(AppImages.likeHeart, width: 16, height: 14,),
                    SizedBox(width: 4,),
                    Text(product.likes.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center,)
                  ],
                ),
              )
            ),
          ],
        ),
        Text(
          product.name,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          textAlign: TextAlign.left,
        ),
        Text(
          '£${product.price.toStringAsFixed(2)}', // Ensures two decimal places
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }
}
