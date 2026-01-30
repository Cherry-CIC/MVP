import 'package:cherry_mvp/features/checkout/purchase_security.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

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
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                  image:
                                      ImageProviderHelper.getImageProvider(product.productImages.first),
                                  fit: BoxFit.cover)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Material(
                          borderRadius: BorderRadius.circular(4),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          type: MaterialType.button,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            height: 32,
                            child: Ink(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.favorite_border,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text('14',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant)),
                                ],
                              ),
                            ),
                          )),
                    ),
                  ],
                )),
            const SizedBox(height: 8),
            Text(
              product.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.quality,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Text(
                  product.size,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      '£${product.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PurchaseSecurity(),
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
                ImageProviderHelper.buildImage(
                  imagePath: product.charityImage,
                  height: 20,
                  width: 20,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
