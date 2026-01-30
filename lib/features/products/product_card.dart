import 'package:cherry_mvp/features/checkout/purchase_security.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';

import '../../core/config/app_strings.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  static const _sizeAbbreviations = {
    'extra small': 'XS',
    'x-small': 'XS',
    'xsmall': 'XS',
    'small': 'S',
    'medium': 'M',
    'large': 'L',
    'extra large': 'XL',
    'x-large': 'XL',
    'xlarge': 'XL',
    'extra extra large': 'XXL',
    'xx-large': 'XXL',
    'xxlarge': 'XXL',
    'one size': 'OS',
  };

  String _formatSizeLabel(String size) {
    if (size.isEmpty) return '';

    final normalized = size.trim().toLowerCase();

    // Check for known size names
    if (_sizeAbbreviations.containsKey(normalized)) {
      return _sizeAbbreviations[normalized]!;
    }

    // For unknown formats (numeric sizes etc.), pass through as-is
    // Truncate to 6 characters max per acceptance criteria
    final result = size.trim();
    return result.length > 6 ? result.substring(0, 6) : result;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          width: 8,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: ImageProviderHelper.getImageProvider(
                              product.productImages.first,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Material(
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      type: MaterialType.button,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 2,
                        ),
                        height: 22,
                        child: Ink(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              Text(
                                '14',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (product.size.isNotEmpty) ...[
                  Text(
                    _formatSizeLabel(product.size),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 14),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "-",
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 14),
                    ),
                  ),
                ],
                Flexible(
                  child: Text(
                    product.quality,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        '£${product.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 16,
                            ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '£${product.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 16,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.productIncl,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PurchaseSecurity(),
                                  fullscreenDialog: true,
                                ),
                              );
                            },
                            child: ImageProviderHelper.buildImage(
                              imagePath: 'assets/images/shield_tick.png',
                              width: 16,
                              height: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (product.charityImage.isNotEmpty)
                    ImageProviderHelper.buildImage(
                      imagePath: product.charityImage,
                      height: 35,
                      width: 35,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
