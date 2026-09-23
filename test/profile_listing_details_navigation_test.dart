import 'dart:async';

import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/product_header_carousel.dart';
import 'package:cherry_mvp/features/products/widgets/product_information.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:cherry_mvp/features/profile/widgets/profile_listings_section.dart';
import 'package:cherry_mvp/features/profile/widgets/seller_listing_card.dart';
import 'package:cherry_mvp/features/shared_widgets/bottom_cta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/unexpected_api_service.dart';

class _CheckoutRepositoryStub implements ICheckoutRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DonationRepositoryStub implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfileListingsRepositoryStub implements IProfileListingsRepository {
  @override
  Future<Result<ProfileListingsPage>> fetchListings({
    int limit = 20,
    String? cursor,
  }) async {
    return Result.success(
      const ProfileListingsPage(
        listings: [
          SellerListing(
            id: 'listing-1',
            name: 'First listing',
            imageUrls: [],
            price: 10,
          ),
          SellerListing(
            id: 'listing-2',
            name: 'Second listing',
            imageUrls: [],
            price: 20,
          ),
        ],
        limit: 20,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

class _ProductRepositoryStub extends ProductRepository {
  _ProductRepositoryStub(this.onFetch) : super(const UnexpectedApiService());

  final Future<Result<Product>> Function(String productId) onFetch;
  final requestedIds = <String>[];

  @override
  Future<Result<Product>> fetchProduct(String productId) {
    requestedIds.add(productId);
    return onFetch(productId);
  }
}

Product _product({
  required String id,
  required String name,
  String userId = 'seller-1',
}) {
  return Product(
    id: id,
    userId: userId,
    name: name,
    description: 'Full description for $name',
    quality: 'Very good',
    productImages: const [AppImages.product1, AppImages.product2],
    donation: 18,
    price: 20,
    securityFee: 2,
    likes: 7,
    number: 1,
    size: 'M',
    postageSizeId: 'small',
  );
}

Future<
  ({
    NavigationProvider navigator,
    ProductViewModel productViewModel,
    CheckoutViewModel checkoutViewModel,
  })
>
_pumpProfile(
  WidgetTester tester, {
  required _ProductRepositoryStub repository,
  Product? selectedProduct,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final navigator = NavigationProvider();
  final productViewModel = ProductViewModel(
    productRepository: repository,
    navigator: navigator,
  );
  if (selectedProduct != null) {
    productViewModel.setProduct(selectedProduct);
  }
  final checkoutViewModel = CheckoutViewModel(
    donationRepository: _DonationRepositoryStub(),
    checkoutRepository: _CheckoutRepositoryStub(),
    navigator: navigator,
    currentUserIdProvider: () => 'seller-1',
  );
  final profileViewModel = ProfileListingsViewModel(
    repository: _ProfileListingsRepositoryStub(),
  );
  await profileViewModel.loadInitialListings();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
        ChangeNotifierProvider<CheckoutViewModel>.value(value: checkoutViewModel),
        ChangeNotifierProvider<ProfileListingsViewModel>.value(
          value: profileViewModel,
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigator.navigatorKey,
        onGenerateRoute: AppRoutes.generateRoute,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileListingsSection(onCreateListing: () {}),
          ),
        ),
      ),
    ),
  );

  return (
    navigator: navigator,
    productViewModel: productViewModel,
    checkoutViewModel: checkoutViewModel,
  );
}

void _expectOwnerDetails(WidgetTester tester, Product product) {
  expect(find.byType(ProductPage), findsOneWidget);
  expect(
    tester.widget<ProductInformation>(find.byType(ProductInformation)).product,
    same(product),
  );
  expect(
    tester.widget<ProductHeaderCarousel>(find.byType(ProductHeaderCarousel)).product.productImages,
    product.productImages,
  );
  expect(find.text(product.name), findsOneWidget);
  expect(find.text(product.description), findsOneWidget);
  expect(find.text(product.size), findsOneWidget);
  expect(find.text(product.quality), findsOneWidget);
  expect(find.text('£18.00'), findsOneWidget);
  expect(find.text('£20.00'), findsOneWidget);
  expect(find.text('7'), findsOneWidget);
  expect(find.byType(BottomCta), findsNothing);
  expect(find.text(AppStrings.productPageBuyNow), findsNothing);
  expect(find.text(AppStrings.productPageMakeOffer), findsNothing);
  expect(find.text(AppStrings.productPageRequestOtherCharity), findsNothing);
  expect(find.text(AppStrings.askSeller), findsNothing);
}

void main() {
  testWidgets('Profile opens full details for each selected own listing', (
    tester,
  ) async {
    final first = _product(id: 'listing-1', name: 'First full listing');
    final second = _product(id: 'listing-2', name: 'Second full listing');
    final repository = _ProductRepositoryStub(
      (id) async => Result.success(id == first.id ? first : second),
    );
    final harness = await _pumpProfile(tester, repository: repository);

    await tester.tap(find.widgetWithText(SellerListingCard, 'First listing'));
    await tester.pumpAndSettle();

    expect(repository.requestedIds, ['listing-1']);
    _expectOwnerDetails(tester, first);
    expect(harness.checkoutViewModel.basketItems, isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SellerListingCard, 'Second listing'));
    await tester.pumpAndSettle();

    expect(repository.requestedIds, ['listing-1', 'listing-2']);
    _expectOwnerDetails(tester, second);
    expect(find.text(first.description), findsNothing);
    expect(harness.checkoutViewModel.basketItems, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading Profile details hides the previously selected product', (
    tester,
  ) async {
    final pending = Completer<Result<Product>>();
    final ownProduct = _product(id: 'listing-1', name: 'Own listing details');
    final publicProduct = _product(
      id: 'public-product',
      name: 'Previously viewed public listing',
      userId: 'another-seller',
    );
    final harness = await _pumpProfile(
      tester,
      repository: _ProductRepositoryStub((_) => pending.future),
      selectedProduct: publicProduct,
    );

    await tester.tap(find.widgetWithText(SellerListingCard, 'First listing'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ProductInformation), findsNothing);
    expect(find.text(publicProduct.name), findsNothing);
    expect(find.text(AppStrings.productPageBuyNow), findsNothing);
    expect(find.byType(BottomCta), findsNothing);

    pending.complete(Result.success(ownProduct));
    await tester.pumpAndSettle();

    _expectOwnerDetails(tester, ownProduct);
    expect(harness.productViewModel.product, same(publicProduct));
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed Profile detail loading retries the same listing', (
    tester,
  ) async {
    final ownProduct = _product(id: 'listing-1', name: 'Own listing details');
    var fetchCount = 0;
    final repository = _ProductRepositoryStub((_) async {
      fetchCount += 1;
      return fetchCount == 1 ? Result.failure('Temporary failure') : Result.success(ownProduct);
    });
    await _pumpProfile(tester, repository: repository);

    await tester.tap(find.widgetWithText(SellerListingCard, 'First listing'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.productPageLoadFailed), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
    expect(find.byType(ProductInformation), findsNothing);
    expect(find.byType(BottomCta), findsNothing);

    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();

    expect(repository.requestedIds, ['listing-1', 'listing-1']);
    _expectOwnerDetails(tester, ownProduct);
    expect(find.text(AppStrings.productPageLoadFailed), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving a pending detail request preserves later selection', (
    tester,
  ) async {
    final pending = Completer<Result<Product>>();
    final ownProduct = _product(id: 'listing-1', name: 'Own listing details');
    final laterProduct = _product(
      id: 'later-product',
      name: 'Later public selection',
      userId: 'another-seller',
    );
    final harness = await _pumpProfile(
      tester,
      repository: _ProductRepositoryStub((_) => pending.future),
    );

    await tester.tap(find.widgetWithText(SellerListingCard, 'First listing'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    harness.productViewModel.goToProductPage(laterProduct);
    await tester.pumpAndSettle();

    pending.complete(Result.success(ownProduct));
    await tester.pumpAndSettle();

    expect(harness.productViewModel.product, same(laterProduct));
    expect(find.text(laterProduct.name), findsOneWidget);
    expect(find.text(ownProduct.name), findsNothing);
    expect(find.text(AppStrings.productPageBuyNow), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
