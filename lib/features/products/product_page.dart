import 'dart:async';

import 'package:cherry_mvp/features/shared_widgets/bottom_cta.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_page.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_repository.dart';
import 'package:cherry_mvp/features/products/listing_details.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/donor_discount_state_store.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/product_highlight_title.dart';
import 'package:cherry_mvp/features/products/widgets/product_information.dart';
import 'package:cherry_mvp/features/products/widgets/seller_information.dart';
import 'package:cherry_mvp/features/products/widgets/product_header_carousel.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, this.product, this.productId});

  final Product? product;
  final String? productId;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Future<Result<Product>>? _productLoad;
  bool _checkingPurchase = false;
  String? _sellerRequestId;
  Future<PublicUser?>? _sellerLoad;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void didUpdateWidget(covariant ProductPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId || oldWidget.product != widget.product) {
      _loadProduct();
    }
  }

  void _loadProduct() {
    final productId = widget.productId;
    _productLoad = productId == null
        ? null
        : context.read<ProductViewModel>().productRepository.fetchProduct(
            productId,
          );
  }

  @override
  Widget build(BuildContext context) {
    if (_productLoad == null) {
      return _buildDetails(
        context,
        widget.product ?? context.watch<ProductViewModel>().product,
      );
    }

    // Keep a Profile request local to this route so Back cannot change the
    // selected Home product when a pending request finishes.
    return FutureBuilder<Result<Product>>(
      future: _productLoad,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final result = snapshot.data;
        if (snapshot.hasError || result == null || !result.isSuccess || result.value == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      AppStrings.productPageLoadFailed,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(_loadProduct),
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _buildDetails(context, result.value);
      },
    );
  }

  Widget _buildDetails(BuildContext context, Product? product) {
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No product selected')),
      );
    }

    final checkoutViewModel = context.watch<CheckoutViewModel>();
    product = context.watch<ProductViewModel>().resolveListing(product);
    final displayedProduct = product;
    final isOwnListing = checkoutViewModel.isOwnProduct(product);
    final canEdit =
        isOwnListing && FeatureFlags.enableListingEdit && context.read<IEditListingRepository>().canEdit(product);
    final unavailable = product.number <= 0 || (product.status != null && product.status != 'active');
    final hasOptionalProductHighlights =
        FeatureFlags.showDonorDiscounts || (!isOwnListing && FeatureFlags.showOtherCharityRequests);
    final sellerId = NavigationProvider.publicProfileUserId(product.userId);
    final sellerLoad = _sellerFuture(context, sellerId);

    return Scaffold(
      bottomNavigationBar: isOwnListing
          ? (canEdit
                ? BottomCta(
                    enabled: true,
                    text: 'Edit listing',
                    onPressed: () => _editListing(displayedProduct),
                  )
                : null)
          : BottomCta(
              enabled: !unavailable && !_checkingPurchase,
              loading: _checkingPurchase,
              text: unavailable ? 'This listing is unavailable' : AppStrings.productPageBuyNow,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              onPressed: () => _buyNow(displayedProduct),
            ),
      body: CustomScrollView(
        slivers: [
          ProductHeaderCarousel(product, canLike: !isOwnListing),
          SliverList.list(
            children: [
              FutureBuilder<PublicUser?>(
                future: sellerLoad,
                builder: (context, snapshot) {
                  final resolvedUsername = snapshot.data?.username.trim();
                  final sellerUsername = (resolvedUsername != null && resolvedUsername.isNotEmpty)
                      ? resolvedUsername
                      : 'User';
                  final profileImageUrl = snapshot.data?.profileImageUrl;

                  return SellerInformation(
                    onViewProfile: sellerId == null
                        ? null
                        : () => context.read<NavigationProvider>().openPublicUserProfile(sellerId),
                    profileImage: profileImageUrl == null ? null : NetworkImage(profileImageUrl),
                    showAskSeller: !isOwnListing,
                    user: UserInformation(
                      username: sellerUsername,
                      location: '',
                      reviewsCount: 0,
                      followersCount: 0,
                      followingCount: 0,
                      rating: 0,
                      awards: 0,
                      hasBuyerDiscounts: false,
                    ),
                    charity: displayedProduct.charity?.imageUrl != null
                        ? Image.network(displayedProduct.charity!.imageUrl)
                        : SizedBox.shrink(),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  );
                },
              ),
              const Divider(thickness: 8),
              ProductInformation(
                product: product,
                padding: const EdgeInsets.all(16),
              ),
              const Divider(thickness: 8),
              ListTile(
                title: Text(AppStrings.productPageDescription),
                titleTextStyle: Theme.of(context).textTheme.titleSmall,
                subtitle: Text(product.description),
                subtitleTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasOptionalProductHighlights) ...[
                const Divider(thickness: 8),
                Column(
                  children: [
                    if (FeatureFlags.showDonorDiscounts)
                      FutureBuilder<bool?>(
                        future: DonorDiscountStateStore.getDonorDiscountState(
                          displayedProduct.id,
                        ),
                        builder: (context, snapshot) {
                          final bool isDonorDiscountActive = snapshot.data ?? false;
                          final donorDiscountLabel = isDonorDiscountActive
                              ? AppStrings.productPageBuyerDiscountActive
                              : AppStrings.productPageDonorDiscountInactive;
                          final donorDiscountDetail = isDonorDiscountActive
                              ? AppStrings.productPageBuy2Get1HalfPrice
                              : AppStrings.productPageDonorDiscountInactiveDetail;

                          return ProductHighlightTile(
                            onTap: () {},
                            leadingText: donorDiscountLabel,
                            trailingText: donorDiscountDetail,
                            trailingIcon: Image.asset(
                              AppImages.sale,
                              height: 24,
                              width: 24,
                            ),
                          );
                        },
                      ),
                    if (!isOwnListing && FeatureFlags.showOtherCharityRequests)
                      ProductHighlightTile(
                        onTap: () {},
                        leadingText: AppStrings.productPageOpenToOtherCharities,
                        trailingText: AppStrings.productPageRequestOtherCharity,
                        trailingIcon: const Icon(Icons.arrow_forward),
                      ),
                  ],
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (!isOwnListing && FeatureFlags.showOffers) ...[
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {},
                            child: Text(
                              AppStrings.productPageMakeOffer,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editListing(Product product) async {
    final result = await context.read<NavigationProvider>().navigateTo(
      AppRoutes.editListing,
      arguments: {'productId': product.id},
    );
    if (!mounted || result is! EditListingResult) return;
    final saved = result.product;
    if (saved != null) {
      context.read<ProductViewModel>().applyListingUpdate(saved);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Listing updated')));
    }
    // Invalidate even after an uncertain response: a timed-out PUT may have
    // committed. Never restore the pre-edit cards when a refresh fails.
    unawaited(context.read<HomeViewModel>().refreshAfterListingEdit());
    unawaited(
      context.read<ProfileListingsViewModel>().refreshAfterListingEdit(),
    );
    setState(() {
      _productLoad = context.read<ProductViewModel>().productRepository.fetchProduct(product.id);
    });
  }

  Future<void> _buyNow(Product displayed) async {
    if (_checkingPurchase) return;
    setState(() => _checkingPurchase = true);
    final vm = context.read<ProductViewModel>();
    final accountVersion = vm.accountStateVersion;
    try {
      final result = await vm.productRepository.fetchProduct(displayed.id);
      if (!mounted || !vm.isAccountStateCurrent(accountVersion)) return;
      final latest = result.value;
      if (!result.isSuccess || latest == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not check this listing. Please try again.'),
          ),
        );
        return;
      }
      if (!sameListingDetails(displayed, latest)) {
        // Updating the page is not consent to buy the changed item. Require a
        // second explicit Buy now after the buyer has reviewed its new details.
        vm.applyListingUpdate(latest);
        setState(() => _productLoad = Future.value(Result.success(latest)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This listing has changed. Please review it before buying.',
            ),
          ),
        );
        return;
      }
      final checkout = context.read<CheckoutViewModel>();
      if (latest.number <= 0 || (latest.status != null && latest.status != 'active') || checkout.isOwnProduct(latest)) {
        return;
      }
      checkout.clearBasket();
      if (!checkout.addItem(latest)) return;
      await context.read<NavigationProvider>().navigateTo(AppRoutes.checkout);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not check this listing. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingPurchase = false);
    }
  }

  Future<PublicUser?> _sellerFuture(BuildContext context, String? userId) {
    if (_sellerRequestId != userId || _sellerLoad == null) {
      _sellerRequestId = userId;
      _sellerLoad = _loadPublicSeller(context, userId);
    }
    return _sellerLoad!;
  }

  Future<PublicUser?> _loadPublicSeller(
    BuildContext context,
    String? userId,
  ) async {
    if (userId == null) return null;
    final repository = context.read<IPublicUserProfileRepository?>();
    if (repository == null) return null;
    try {
      final result = await repository.fetchUser(userId);
      return result.isSuccess ? result.value : null;
    } catch (_) {
      return null;
    }
  }
}
