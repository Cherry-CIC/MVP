import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/config/app_spacing.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/home/widgets/ad_example.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard_loading_widget.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard_error_widget.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard_empty_widget.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      _hasInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        unawaited(
          context.read<ProductViewModel>().hydrateLikedProducts(),
        );
        unawaited(context.read<HomeViewModel>().fetchProducts());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, homeViewModel, _) {
        final navigator = Provider.of<NavigationProvider>(context, listen: false);
        final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
        final products = homeViewModel.products;
        final status = homeViewModel.status;

        if (status.type == StatusType.loading) {
          return const SliverPadding(
            padding: EdgeInsets.all(12),
            sliver: SliverToBoxAdapter(child: DashboardLoadingWidget()),
          );
        }

        if (status.type == StatusType.failure) {
          return SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverToBoxAdapter(
              child: DashboardErrorWidget(
                errorMessage: status.message,
                onRetry: () => homeViewModel.fetchProducts(),
              ),
            ),
          );
        }

        if (products.isEmpty) {
          return const SliverPadding(
            padding: EdgeInsets.all(12),
            sliver: SliverToBoxAdapter(child: DashboardEmptyWidget()),
          );
        }

        final size = MediaQuery.sizeOf(context);
        final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.4);

        final cardWidth = (size.width - 24 - 12) / 2;
        const imageAspectRatio = AppSpacing.imageContainerAspectRatio;
        final imageHeight = cardWidth / imageAspectRatio;

        final textHeight = 120.0 * textScale;
        final totalCardHeight = imageHeight + textHeight;

        final numProductRows = (products.length / 2).ceil();
        final numAds = FeatureFlags.showCharityAds ? (products.length / 6).floor() : 0;
        final loaderCount = homeViewModel.isLoadingMore ? 1 : 0;
        final totalCount = numProductRows + numAds + loaderCount;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (homeViewModel.isLoadingMore && index == totalCount - 1) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // Insert adverts after every 3 product rows when the advert feature is ready.
                if (FeatureFlags.showCharityAds && (index + 1) % 4 == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: AdExample(),
                  );
                }

                final productRowIndex = FeatureFlags.showCharityAds ? index - (index ~/ 4) : index;
                final firstProductInRowIndex = productRowIndex * 2;
                final secondProductInRowIndex = firstProductInRowIndex + 1;

                if (firstProductInRowIndex >= products.length) return null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    height: totalCardHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildProductItem(
                            context,
                            products[firstProductInRowIndex],
                            productViewModel,
                            navigator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: secondProductInRowIndex < products.length
                              ? _buildProductItem(
                                  context,
                                  products[secondProductInRowIndex],
                                  productViewModel,
                                  navigator,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: totalCount,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    Product product,
    ProductViewModel productViewModel,
    NavigationProvider navigator,
  ) {
    return GestureDetector(
      onTap: () {
        productViewModel.setProduct(product);
        navigator.navigateTo(AppRoutes.product);
      },
      child: ProductCard(
        key: ValueKey(product.id),
        product: product,
      ),
    );
  }
}
