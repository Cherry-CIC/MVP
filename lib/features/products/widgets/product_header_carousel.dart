import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/widgets/image_carousel.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/product_photo_viewer.dart';
import 'package:cherry_mvp/features/products/widgets/product_safety_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductHeaderCarousel extends StatelessWidget {
  final Product product;
  final bool canLike;
  final Widget? ownerActions;
  final bool showSafetyActions;
  final ValueChanged<ProductSafetyMenuAction>? onSafetyActionSelected;

  const ProductHeaderCarousel(
    this.product, {
    super.key,
    this.canLike = true,
    this.ownerActions,
    this.showSafetyActions = false,
    this.onSafetyActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final images = product.productImages.map(ImageProviderHelper.getImageProvider).toList();

    return SliverAppBar(
      toolbarHeight: 72,
      leadingWidth: 80,
      leading: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
        child: BackButton(
          color: AppColors.red,
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            iconSize: 28,
            fixedSize: const Size.square(56),
          ),
        ),
      ),
      actions: [
        if (ownerActions != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Center(child: ownerActions!),
          ),
        if (showSafetyActions && onSafetyActionSelected != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: _HeaderIconSurface(
              child: ProductSafetyActionsButton(
                onSelected: onSafetyActionSelected!,
              ),
            ),
          ),
      ],
      expandedHeight: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.top,
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
                  images: images,
                  onImageTap: (index) => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => ProductPhotoViewer(images: images, initialIndex: index),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: 24,
                bottom: 16,
                child: Consumer<ProductViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isOwnProduct(product)) {
                      return const SizedBox.shrink();
                    }
                    final bool isLiked = viewModel.isProductLiked(product.id);
                    final int count = viewModel.getLikesCount(product);
                    const unlikedColor = Color(0xFF595959);

                    return Semantics(
                      button: canLike,
                      toggled: isLiked,
                      label: isLiked
                          ? '${AppStrings.unlikeProduct}, $count likes'
                          : '${AppStrings.likeProduct}, $count likes',
                      excludeSemantics: true,
                      onTap: canLike ? () => viewModel.toggleLike(product) : null,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: canLike ? () => viewModel.toggleLike(product) : null,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: kMinInteractiveDimension,
                            minHeight: kMinInteractiveDimension,
                          ),
                          child: Material(
                            color: Colors.white,
                            elevation: 4,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                          excludeFromSemantics: true,
                                        )
                                      : const Icon(
                                          Icons.favorite_outline,
                                          size: 24,
                                          color: unlikedColor,
                                        ),
                                  const SizedBox(width: 8),
                                  Text(
                                    count.toString(),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: isLiked ? Colors.red : unlikedColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

class _HeaderIconSurface extends StatelessWidget {
  const _HeaderIconSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: SizedBox.square(
          dimension: kMinInteractiveDimension,
          child: IconTheme.merge(
            data: const IconThemeData(color: Colors.white),
            child: child,
          ),
        ),
      ),
    );
  }
}
