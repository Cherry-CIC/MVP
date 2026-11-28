import 'dart:async';

import 'package:cherry_mvp/features/search/widgets/search.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/config/app_spacing.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_card.dart';
import 'package:cherry_mvp/features/donation/donation_page.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/bottom_nav_bar.dart';
import 'package:cherry_mvp/features/liked_items/liked_items_view_model.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/blocked_users.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LikedItemsPage extends StatelessWidget {
  const LikedItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LikedItemsViewModel>(
      create: (context) => LikedItemsViewModel(
        deletedListings: context.read<DeletedListings?>(),
        blockedUsers: context.read<BlockedUsers?>(),
        productRepository: context.read<ProductRepository>(),
        productViewModel: context.read<ProductViewModel>(),
      )..loadLikedProducts(),
      child: const _LikedItemsView(),
    );
  }
}

class LikedItemsSelectionBar extends StatelessWidget {
  const LikedItemsSelectionBar({
    required this.selectedTab,
    required this.onSelected,
    super.key,
  });

  final LikedItemsTab selectedTab;
  final ValueChanged<LikedItemsTab> onSelected;

  static const _tabs = [
    (AppStrings.likedItemsTab, LikedItemsTab.items),
    (AppStrings.likedCharitiesTab, LikedItemsTab.charities),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: _tabs
              .map(
                (tab) => _LikedTabButton(
                  key: ValueKey('liked-tab-${tab.$2.name}'),
                  label: tab.$1,
                  semanticsLabel: tab.$1,
                  isSelected: selectedTab == tab.$2,
                  onTap: () => onSelected(tab.$2),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _LikedTabButton extends StatelessWidget {
  const _LikedTabButton({
    required this.label,
    required this.semanticsLabel,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String semanticsLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colourScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        excludeSemantics: true,
        label: semanticsLabel,
        onTap: onTap,
        child: Material(
          color: isSelected ? colourScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          elevation: isSelected ? 2 : 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isSelected ? colourScheme.primary : colourScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LikedItemsView extends StatelessWidget {
  const _LikedItemsView();

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
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: LikedItemsSelectionBar(
                    selectedTab: viewModel.selectedTab,
                    onSelected: viewModel.selectTab,
                  ),
                ),
                Expanded(
                  child: viewModel.selectedTab == LikedItemsTab.charities
                      ? _buildCharitiesContent(viewModel)
                      : _buildProductsContent(viewModel),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: CherryBottomNavBar(
        selectedIndex: CherryNavIndices.profile,
        onItemSelected: (index) => _handleNavTap(context, index),
        selectedColor: Theme.of(context).colorScheme.primary,
        unselectedColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildProductsContent(LikedItemsViewModel viewModel) {
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
  }

  Widget _buildCharitiesContent(LikedItemsViewModel viewModel) {
    switch (viewModel.charitiesStatus) {
      case LikedItemsStatus.initial:
      case LikedItemsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LikedItemsStatus.empty:
        return const _LikedCharitiesEmptyState();
      case LikedItemsStatus.error:
        return _LikedItemsErrorState(
          message: viewModel.charitiesErrorMessage ?? AppStrings.likedCharitiesLoadError,
          onRetry: viewModel.retryCharities,
        );
      case LikedItemsStatus.loaded:
        return _LikedCharitiesList(charities: viewModel.charities);
    }
  }

  void _handleNavTap(BuildContext context, int index) async {
    final navigator = context.read<NavigationProvider>();

    if (index == CherryNavIndices.home) {
      final homeViewModel = context.read<HomeViewModel?>();
      if (homeViewModel != null) {
        unawaited(homeViewModel.selectHomeCategory(null));
      }
      navigator.navigateToAndRemoveUntil(AppRoutes.home, (_) => false);
      return;
    }

    if (index == CherryNavIndices.discover) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(CherryNavIndices.discover);
      } else {
        navigator.navigateTo(AppRoutes.discover);
      }
      return;
    }

    if (FeatureFlags.showInbox && index == CherryNavIndices.inbox) {
      navigator.navigateToAndRemoveUntil(AppRoutes.home, (_) => false);
      return;
    }

    if (index == CherryNavIndices.give) {
      final posted = await showDialog<bool>(
        context: context,
        builder: (context) => const Dialog.fullscreen(child: DonationPage()),
      );
      if (posted == true && context.mounted) {
        context.read<ProfileListingsViewModel>().refreshListings();
        navigator.goBack();
      }
      return;
    }

    if (FeatureFlags.showSearchNavigation && index == CherryNavIndices.search) {
      openSearch(context);
      return;
    }

    if (index == CherryNavIndices.profile && Navigator.of(context).canPop()) {
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
    final cardHeight = imageHeight + (128.0 * textScale);

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

class _LikedCharitiesList extends StatelessWidget {
  const _LikedCharitiesList({required this.charities});

  final List<Charity> charities;

  static final DiscoverRepository _defaultDiscoverRepository = DiscoverRepository();

  Future<void> _handleUnlike(BuildContext context, Charity charity) async {
    final productViewModel = context.read<ProductViewModel>();
    if (productViewModel.isCharityLikeUpdatePending(
      charity.id,
      charityName: charity.name,
    )) {
      return;
    }
    final viewModel = context.read<LikedItemsViewModel>();
    final removed = await viewModel.unlikeCharity(charity);
    if (!removed && context.mounted) {
      final message = viewModel.charitiesErrorMessage ?? 'Unable to remove this liked charity.';
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoverRepository = context.read<DiscoverRepository?>() ?? _defaultDiscoverRepository;
    final productViewModel = context.watch<ProductViewModel>();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: charities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final charity = charities[index];
        final discoverCharity = discoverRepository.findCharity(
          id: charity.id,
          name: charity.name,
        );
        final title = discoverCharity?.charityName ?? charity.name;
        final suppliedDescription = charity.description?.trim();
        final description = (suppliedDescription != null && suppliedDescription.isNotEmpty)
            ? suppliedDescription
            : (discoverCharity?.description ?? AppStrings.charityDescription);
        final assetUrl = charity.imageUrl.startsWith('assets/') ? charity.imageUrl : null;
        final imagePath = discoverCharity?.charityImage ?? assetUrl ?? AppImages.discoverImage1;
        final logoPath = discoverCharity?.charityLogo ?? assetUrl;
        final likes = productViewModel.getCharityLikesCount(
          charity.id,
          charityName: charity.name,
          fallback: charity.likes,
        );

        return DiscoverCharityCard(
          key: ValueKey('liked-charity-${charity.id}'),
          charityId: charity.id,
          title: title,
          description: description,
          imagePath: imagePath,
          logoPath: logoPath,
          logoUsesDarkBackground: discoverCharity?.logoUsesDarkBackground ?? false,
          likes: likes,
          isLiked: true,
          onLikePressed: () => unawaited(_handleUnlike(context, charity)),
        );
      },
    );
  }
}

class _LikedCharitiesEmptyState extends StatelessWidget {
  const _LikedCharitiesEmptyState();

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
              AppStrings.likedCharitiesEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.likedCharitiesEmptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(CherryNavIndices.discover);
                } else {
                  context.read<NavigationProvider>().navigateTo(
                    AppRoutes.discover,
                  );
                }
              },
              child: const Text(AppStrings.likedCharitiesBrowseCharities),
            ),
          ],
        ),
      ),
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
