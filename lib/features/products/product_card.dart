import 'package:cherry_mvp/features/checkout/purchase_security.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/core/config/app_spacing.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';

import '../../core/config/app_strings.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isLiked = false;
  
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

  @override
  Widget build(BuildContext context) {
    final int displayLikes = widget.product.likes + (_isLiked ? 1 : 0);

    return Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.onTap,
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
                              widget.product.productImages.first,
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
                      onTap: () {
                        setState(() {
                          _isLiked = !_isLiked;
                        });
                      },
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
                              _isLiked
                                  ? Image.asset(
                                      AppImages.likeHeart,
                                      height: 16,
                                      fit: BoxFit.contain,
                                      color: Colors.red,
                                    )
                                  : Icon(
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
                                      color: _isLiked ? Colors.red : AppColors.grey,
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
              widget.product.name,
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
                if (widget.product.size.isNotEmpty) ...[
                  Text(
                    _formatSizeLabel(widget.product.size),
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
                    widget.product.quality,
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '£${widget.product.price.toStringAsFixed(2)}',
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
                            '£${widget.product.price.toStringAsFixed(2)}',
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
                  if (widget.product.charityImage.isNotEmpty)
                    ImageProviderHelper.buildImage(
                      imagePath: widget.product.charityImage,
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
