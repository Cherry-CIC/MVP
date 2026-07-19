import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/config/app_spacing.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/features/donation/donation_page.dart';
import 'package:cherry_mvp/features/home/widgets/bottom_nav_bar.dart';
import 'package:cherry_mvp/features/liked_items/liked_items_view_model.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LikedItemsPage extends StatelessWidget {
  const LikedItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LikedItemsViewModel>(
      create: (context) => LikedItemsViewModel(
        productRepository: context.read<ProductRepository>(),
        productViewModel: context.read<ProductViewModel>(),
      )..loadLikedProducts(),
      child: const _LikedItemsView(),
    );
  }
}

class _LikedItemsView extends StatelessWidget {
  const _LikedItemsView();

  static const int _homeNavIndex = 0;
  static const int _inboxNavIndex = 1;
  static const int _giveNavIndex = FeatureFlags.showInbox ? 2 : 1;
  static const int _searchNavIndex = _giveNavIndex + 1;
  static const int _profileNavIndex = _giveNavIndex + (FeatureFlags.showSearch ? 2 : 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        title: const Text(AppStrings.likedItemsTitle),
      ),
      body: SafeArea(
        child: Consumer<LikedItemsViewModel>(
          builder: (context, viewModel, _) {
            switch (viewModel.status) {
              case LikedItemsStatus.initial:
              case LikedItemsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case LikedItemsStatus.empty:
                return const _LikedItemsEmptyState();
              case LikedItemsStatus.error:
                return _LikedItemsErrorState(
                  message: viewModel.errorMessage ?? AppStrings.likedItemsLoadError,
                  onRetry: viewModel.retry,
                );
              case LikedItemsStatus.loaded:
                return _LikedProductsGrid(products: viewModel.products);
            }
          },
        ),
      ),
      bottomNavigationBar: CherryBottomNavBar(
        selectedIndex: _profileNavIndex,
        onItemSelected: (index) => _handleNavTap(context, index),
        selectedColor: Theme.of(context).colorScheme.primary,
        unselectedColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _handleNavTap(BuildContext context, int index) {
    final navigator = context.read<NavigationProvider>();

    if (index == _homeNavIndex) {
      navigator.navigateToAndRemoveUntil(AppRoutes.home, (_) => false);
      return;
    }

    if (FeatureFlags.showInbox && index == _inboxNavIndex) {
      navigator.navigateToAndRemoveUntil(AppRoutes.home, (_) => false);
      return;
    }

    if (index == _giveNavIndex) {
      showDialog(
        context: context,
        builder: (context) => const Dialog.fullscreen(child: DonationPage()),
      );
      return;
    }

    if (FeatureFlags.showSearch && index == _searchNavIndex) {
      context.read<SearchController>().openView();
      return;
    }

    if (index == _profileNavIndex && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _LikedProductsGrid extends StatelessWidget {
  const _LikedProductsGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.4);
    final cardWidth = (size.width - 24 - 12) / 2;
    final imageHeight = cardWidth / AppSpacing.imageContainerAspectRatio;
    final cardHeight = imageHeight + (120.0 * textScale);

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 24,
        crossAxisSpacing: 12,
        mainAxisExtent: cardHeight,
      ),
      itemBuilder: (context, index) {
        final product = products[index];

        return ProductCard(
          key: ValueKey(product.id),
          product: product,
          onTap: () => context.read<ProductViewModel>().goToProductPage(product),
          onLikePressed: () => context.read<LikedItemsViewModel>().unlikeProduct(product),
        );
      },
    );
  }
}

class _LikedItemsEmptyState extends StatelessWidget {
  const _LikedItemsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.likedItemsEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.likedItemsEmptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  context.read<NavigationProvider>().navigateToAndRemoveUntil(AppRoutes.home, (_) => false),
              child: const Text(AppStrings.likedItemsBrowseProducts),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikedItemsErrorState extends StatelessWidget {
  const _LikedItemsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
