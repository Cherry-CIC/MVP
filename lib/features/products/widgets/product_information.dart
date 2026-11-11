import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/products/widgets/product_quality_label.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/utils/security_fee.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';

class ProductInformation extends StatelessWidget {
  final Product product;
  final EdgeInsets? padding;

  const ProductInformation({super.key, required this.product, this.padding});

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryPriceColor = isDark ? colours.primary : AppColors.primaryAction;
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
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
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
                            '£${product.priceIncludingSecurityFee.toStringAsFixed(2)}',
                            style: priceStyle.copyWith(color: primaryPriceColor),
                          ),
                          Image.asset(
                            AppImages.shieldTick,
                            width: 20,
                            height: 20,
                            excludeFromSemantics: true,
                          ),
                        ],
                      ),
                    ],
                  ),
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
