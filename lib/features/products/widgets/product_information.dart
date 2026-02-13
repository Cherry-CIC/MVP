import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/checkout/purchase_security.dart';
import 'package:flutter/material.dart';

class ProductInformation extends StatelessWidget {
  final Product product;
  final EdgeInsets? padding;

  const ProductInformation({super.key, required this.product, this.padding});

  void _showPurchaseSecurity(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PurchaseSecurity(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name),
          const SizedBox(height: 4.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showPurchaseSecurity(context),
                child: SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('£${product.donation.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('£${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary)),
                          const SizedBox(width: 4),
                          Image.asset(
                            AppImages.shieldTick,
                            width: 16,
                            height: 16,
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 48,
                child: Text(product.size,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(product.quality,
                    style: const TextStyle(color: AppColors.green)),
              ),
              Icon(
                Icons.workspace_premium,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          )
        ],
      ),
    );
  }
}
