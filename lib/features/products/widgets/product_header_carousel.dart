import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/widgets/image_carousel.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:flutter/material.dart';

class ProductHeaderCarousel extends StatelessWidget {
  final Product product;
  const ProductHeaderCarousel(this.product, {super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      leading: const BackButton(color: Colors.white),
      expandedHeight: MediaQuery.of(context).size.width -
          MediaQuery.of(context).padding.top,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ImageCarousel(
                  images: product.product_images
                      .map((path) => ImageProviderHelper.getImageProvider(path))
                      .toList(),
                ),
              ),
              PositionedDirectional(
                end: 24,
                bottom: 16,
                child: Material(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.favorite,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          product.likes.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                            color:
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}