import 'package:cherry_mvp/features/shared_widgets/bottom_cta.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/donor_discount_state_store.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/product_highlight_title.dart';
import 'package:cherry_mvp/features/products/widgets/product_information.dart';
import 'package:cherry_mvp/features/products/widgets/seller_information.dart';
import 'package:cherry_mvp/features/products/widgets/product_header_carousel.dart';

class ProductPage extends StatefulWidget {
  final String? productId;

  const ProductPage({super.key, this.productId});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Future<Result<Product>>? _productLoad;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void didUpdateWidget(covariant ProductPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
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
    if (widget.productId == null) {
      return _buildDetails(context, context.watch<ProductViewModel>().product);
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
    final isOwnListing = checkoutViewModel.isOwnProduct(product);
    final hasOptionalProductHighlights =
        FeatureFlags.showDonorDiscounts || (!isOwnListing && FeatureFlags.showOtherCharityRequests);

    return Scaffold(
      bottomNavigationBar: isOwnListing
          ? null
          : BottomCta(
              enabled: true,
              text: AppStrings.productPageBuyNow,
              onPressed: () {
                checkoutViewModel.clearBasket();
                if (!checkoutViewModel.addItem(product)) {
                  return;
                }
                context.read<NavigationProvider>().navigateTo(
                  AppRoutes.checkout,
                );
              },
            ),
      body: CustomScrollView(
        slivers: [
          ProductHeaderCarousel(product, canLike: !isOwnListing),
          SliverList.list(
            children: [
              FutureBuilder<String?>(
                future: UsernameService.getUsername(product.userId ?? ''),
                builder: (context, snapshot) {
                  final resolvedUsername = snapshot.data?.trim();
                  final sellerUsername = (resolvedUsername != null && resolvedUsername.isNotEmpty)
                      ? resolvedUsername
                      : 'User';

                  return SellerInformation(
                    showAskSeller: !isOwnListing,
                    user: UserInformation(
                      username: sellerUsername,
                      // TODO remove filler values
                      location: 'New York, USA',
                      reviewsCount: 120,
                      followersCount: 300,
                      followingCount: 150,
                      rating: 3.5,
                      awards: 37,
                      hasBuyerDiscounts: true,
                    ),
                    charity: product.charity?.imageUrl != null
                        ? Image.network(product.charity!.imageUrl)
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
                          product.id,
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
}
