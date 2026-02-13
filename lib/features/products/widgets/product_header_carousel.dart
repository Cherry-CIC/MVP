import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/widgets/image_carousel.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                  images: product.productImages
                      .map((path) => ImageProviderHelper.getImageProvider(path))
                      .toList(),
                ),
              ),
              PositionedDirectional(
                end: 24,
                bottom: 16,
                child: Consumer<ProductViewModel>(
                  builder: (context, viewModel, child) {
                    final bool isLiked = viewModel.isLiked;
                    final int count = viewModel.likesCount;

                    return GestureDetector(
                      onTap: () => viewModel.toggleLike(),
                      child: Material(
                        color: Colors.white,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              isLiked
                                  ? Image.asset(
                                      AppImages.likeHeart,
                                      height: 24,
                                      fit: BoxFit.contain,
                                      color: Colors.red,
                                    )
                                  : Icon(
                                      Icons.favorite_outline,
                                      size: 24,
                                      color: AppColors.grey,
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                count.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: isLiked
                                          ? Colors.red
                                          : AppColors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
