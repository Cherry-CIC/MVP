import 'package:cherry_mvp/features/shared_widgets/bottom_cta.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/delete_listing_view_model.dart';
import 'package:cherry_mvp/features/products/widgets/delete_listing_dialog.dart';
import 'package:cherry_mvp/features/products/widgets/listing_actions_menu.dart';
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
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_page.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:cherry_mvp/features/products/widgets/product_highlight_title.dart';
import 'package:cherry_mvp/features/products/widgets/product_information.dart';
import 'package:cherry_mvp/features/products/widgets/product_safety_actions.dart';
import 'package:cherry_mvp/features/products/widgets/seller_information.dart';
import 'package:cherry_mvp/features/products/widgets/product_header_carousel.dart';
import 'package:cherry_mvp/features/products/widgets/sold_listing_banner.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, this.product, this.productId, this.fromOwnListings = false});

  final Product? product;
  final String? productId;
  final bool fromOwnListings;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Future<Result<Product>>? _productLoad;
  String? _requestedProductId;
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
    _requestedProductId = productId;
    _productLoad = productId == null
        ? null
        : context.read<ProductViewModel>().productRepository.fetchProduct(
            productId,
          );
  }

  @override
  Widget build(BuildContext context) {
    final deleted = context.watch<DeletedListings?>();
    final id = widget.productId ?? widget.product?.id ?? context.read<ProductViewModel>().product?.id;
    if (id != null && deleted?.contains(id) == true) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This listing is no longer available.')),
      );
    }
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
                      onPressed: () => _refreshProduct(_requestedProductId!),
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
    final displayedProduct = product;
    final isOwnListing = checkoutViewModel.isOwnProduct(displayedProduct);
    final canBuy = !isOwnListing && !displayedProduct.isSold;
    final deletion = context.watch<DeleteListingViewModel?>();
    final actionSession = deletion?.session;
    final canEdit =
        isOwnListing &&
        !displayedProduct.isSold &&
        (context.read<IEditListingRepository?>()?.canEdit(displayedProduct) ?? false);
    final knownSold = displayedProduct.status?.toLowerCase() == 'sold' || displayedProduct.number <= 0;
    final canDelete =
        deletion?.canDelete(displayedProduct.id, ownerId: displayedProduct.userId, knownSold: knownSold) ?? false;
    final hasOptionalProductHighlights =
        !displayedProduct.isSold &&
        (FeatureFlags.showDonorDiscounts || (canBuy && FeatureFlags.showOtherCharityRequests));
    final sellerId = NavigationProvider.publicProfileUserId(displayedProduct.userId);
    final sellerLoad = _sellerFuture(context, sellerId);
    final canUseSafetyActions = !isOwnListing && sellerId != null && sellerId.isNotEmpty;

    return Scaffold(
      bottomNavigationBar: !canBuy
          ? null
          : BottomCta(
              enabled: true,
              text: AppStrings.productPageBuyNow,
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              onPressed: () {
                checkoutViewModel.clearBasket();
                if (!checkoutViewModel.addItem(displayedProduct)) {
                  return;
                }
                context.read<NavigationProvider>().navigateTo(
                  AppRoutes.checkout,
                );
              },
            ),
      body: CustomScrollView(
        slivers: [
          ProductHeaderCarousel(
            displayedProduct,
            canLike: !isOwnListing,
            ownerActions: canEdit || canDelete
                ? ListingActionsMenu(
                    listingName: displayedProduct.name,
                    busy: deletion?.isPending(displayedProduct.id) ?? false,
                    onEdit: canEdit ? () => _editListing(displayedProduct) : null,
                    onDelete: canDelete
                        ? () => requestListingDeletion(
                            context,
                            productId: displayedProduct.id,
                            ownerId: displayedProduct.userId!,
                            knownSold: knownSold,
                            actionSession: actionSession!,
                            onRemoved: _leaveDeletedListing,
                            onRefreshDetails: () => _refreshProduct(displayedProduct.id),
                          )
                        : null,
                  )
                : null,
            showSafetyActions: canUseSafetyActions,
            onSafetyActionSelected: (action) => _handleSafetyAction(
              context,
              action,
              displayedProduct,
              sellerId!,
            ),
          ),
          SliverList.list(
            children: [
              if (displayedProduct.isSold) SoldListingBanner(showSellerMessage: isOwnListing),
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
                    showAskSeller: canBuy,
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
                    charityDetails: displayedProduct.charity,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  );
                },
              ),
              const Divider(thickness: 8),
              ProductInformation(
                product: displayedProduct,
                padding: const EdgeInsets.all(16),
              ),
              const Divider(thickness: 8),
              ListTile(
                title: Text(AppStrings.productPageDescription),
                titleTextStyle: Theme.of(context).textTheme.titleSmall,
                subtitle: Text(displayedProduct.description),
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
                    if (canBuy && FeatureFlags.showOtherCharityRequests)
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
                    if (canBuy && FeatureFlags.showOffers) ...[
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

  Future<PublicUser?> _sellerFuture(BuildContext context, String? userId) {
    if (_sellerRequestId != userId || _sellerLoad == null) {
      _sellerRequestId = userId;
      _sellerLoad = _loadPublicSeller(context, userId);
    }
    return _sellerLoad!;
  }

  void _refreshProduct(String productId) {
    if (!mounted) return;
    setState(() {
      _requestedProductId = productId;
      _productLoad = context.read<ProductViewModel>().productRepository.fetchProduct(productId);
    });
  }

  void _leaveDeletedListing() {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final navigator = Navigator.of(context);
    if (widget.fromOwnListings && navigator.canPop()) {
      navigator.pop();
    } else {
      context.read<NavigationProvider>().replaceWith(AppRoutes.myListings);
    }
  }

  Future<void> _editListing(Product product) async {
    final actions = context.read<DeleteListingViewModel?>();
    final session = actions?.session;
    final result = await context.read<NavigationProvider>().navigateTo(
      AppRoutes.editListing,
      arguments: {'productId': product.id},
    );
    if (!mounted || (session != null && !actions!.isCurrent(session)) || result is! EditListingResult) return;
    if (result.product != null) {
      context.read<ProductViewModel>().applyListingUpdate(result.product!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing updated')),
      );
    }
    await Future.wait([
      context.read<HomeViewModel>().refreshAfterListingEdit(),
      context.read<ProfileListingsViewModel>().refreshAfterListingEdit(),
    ]);
    if (mounted) _refreshProduct(product.id);
  }

  Future<PublicUser?> _loadPublicSeller(BuildContext context, String? userId) async {
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

  Future<void> _handleSafetyAction(
    BuildContext context,
    ProductSafetyMenuAction action,
    Product product,
    String sellerId,
  ) async {
    switch (action) {
      case ProductSafetyMenuAction.reportProduct:
        await _submitReport(
          context,
          title: AppStrings.productPageReportProductTitle,
          submit: (viewModel, draft) => viewModel.reportProduct(
            product,
            reason: draft.reason,
            message: draft.message,
          ),
        );
        break;
      case ProductSafetyMenuAction.reportSeller:
        await _submitReport(
          context,
          title: AppStrings.productPageReportSellerTitle,
          submit: (viewModel, draft) => viewModel.reportSeller(
            sellerId,
            reason: draft.reason,
            message: draft.message,
          ),
        );
        break;
      case ProductSafetyMenuAction.blockSeller:
        await _blockSeller(context, sellerId);
        break;
    }
  }

  Future<void> _submitReport(
    BuildContext context, {
    required String title,
    required Future<Result<void>> Function(
      ProductViewModel viewModel,
      ReportDraft draft,
    )
    submit,
  }) async {
    final draft = await showReportProductSheet(context, title: title);
    if (draft == null || !context.mounted) {
      return;
    }

    final result = await submit(context.read<ProductViewModel>(), draft);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess ? AppStrings.productPageReportSubmitted : result.error ?? AppStrings.productPageReportFailed,
        ),
      ),
    );
  }

  Future<void> _blockSeller(BuildContext context, String sellerId) async {
    final confirmed = await showBlockSellerDialog(context);
    if (!confirmed || !context.mounted) {
      return;
    }

    final result = await context.read<ProductViewModel>().blockSeller(sellerId);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? AppStrings.productPageBlockSellerSuccess
              : result.error ?? AppStrings.productPageBlockSellerFailed,
        ),
      ),
    );
  }
}
