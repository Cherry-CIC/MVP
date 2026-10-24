import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/products/widgets/product_quality_label.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';

class ProductInformation extends StatelessWidget {
  final Product product;
  final EdgeInsets? padding;

  const ProductInformation({super.key, required this.product, this.padding});

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    const detailStyle = TextStyle(
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w800,
      fontSize: 18,
    );
    const priceStyle = TextStyle(
      fontFamily: 'InstrumentSansPricing',
      fontWeight: FontWeight.w700,
      fontSize: 18,
    );

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(product.name, style: detailStyle.copyWith(fontSize: 20)),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              GestureDetector(
                onTap: context.read<ProductViewModel>().showPurchaseSecurity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      '£${product.donation.toStringAsFixed(2)}',
                      style: priceStyle.copyWith(color: colours.onSurfaceVariant),
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Text(
                          '£${product.price.toStringAsFixed(2)}',
                          style: priceStyle.copyWith(color: colours.primary),
                        ),
                        Image.asset(AppImages.shieldTick, width: 20, height: 20),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                product.size,
                style: detailStyle.copyWith(color: colours.onSurfaceVariant),
              ),
              ProductQualityLabel(product.quality, style: detailStyle),
              if (FeatureFlags.showProductBadge) Icon(Icons.workspace_premium, color: colours.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}
