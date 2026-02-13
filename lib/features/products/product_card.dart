import 'package:cherry_mvp/features/checkout/purchase_security.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/core/config/app_spacing.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:provider/provider.dart';

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

    if (_sizeAbbreviations.containsKey(normalized)) {
      return _sizeAbbreviations[normalized]!;
    }

    final result = size.trim();
    return result.length > 6 ? result.substring(0, 6) : result;
  }

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
    return Consumer<ProductViewModel>(
      builder: (context, viewModel, child) {
        final bool isLiked = viewModel.isProductLiked(product.id);
        final int displayLikes = viewModel.getLikesCount(product);

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
                  aspectRatio: AppSpacing.imageContainerAspectRatio,
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
                        child: GestureDetector(
                          onTap: () => viewModel.toggleLike(product),
                          child: Material(
                            borderRadius: BorderRadius.circular(4),
                            elevation: 2,
                            color: Colors.white,
                            type: MaterialType.button,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  isLiked
                                      ? Image.asset(
                                          AppImages.likeHeart,
                                          height: 16,
                                          fit: BoxFit.contain,
                                          color: Colors.red,
                                        )
                                      : const Icon(
                                          Icons.favorite_outline,
                                          size: 16,
                                          color: AppColors.grey,
                                        ),
                                  const SizedBox(width: 4),
                                  Text(
                                    displayLikes.toString(),
                                    style: Theme.of(context).textTheme.labelSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isLiked ? Colors.red : AppColors.grey,
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
                      GestureDetector(
                        onTap: () => _showPurchaseSecurity(context),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '£${product.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontSize: 14,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                const SizedBox(width: 4),
                                Image.asset(
                                  AppImages.shieldTick,
                                  width: 16,
                                  height: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
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
      },
    );
  }
}
