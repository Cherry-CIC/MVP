import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/widgets/product_image_card.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemsInSupport extends StatelessWidget {
  final List<Product> products;

  const ItemsInSupport({required this.products, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
        child: Column(
          children: [
            Row(
              children: [
                Text(AppStrings.itemsInSupportText,
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text(AppStrings.seeAllText),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 100,
              child: ListView.separated(
                separatorBuilder: (context, index) => const SizedBox(width: 5),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return GestureDetector(
                    onTap: () {
                      final productViewModel =
                          Provider.of<ProductViewModel>(context, listen: false);
                      productViewModel.setProduct(product);
                      Navigator.pushNamed(context, AppRoutes.product);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: ProductImageCard(product: product),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
