import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';

class ProductInformation extends StatelessWidget {
  final Product product;
  final EdgeInsets? padding;

  const ProductInformation({super.key, required this.product, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(product.name),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: context.read<ProductViewModel>().showPurchaseSecurity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        '£${product.donation.toStringAsFixed(2)}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      Row(
                        spacing: 4,
                        children: [
                          Text(
                            '£${product.price.toStringAsFixed(2)}',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                          Image.asset(AppImages.shieldTick, width: 16, height: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    Text(
                      product.size,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 16),
                    Text(product.quality, style: const TextStyle(color: AppColors.green)),
                    Icon(
                      Icons.workspace_premium,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
