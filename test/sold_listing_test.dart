import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/sold_listing_banner.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/widgets/seller_listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';
import 'support/edit_listing_repository_stub.dart';

Map<String, dynamic> _listingJson(Object? status) => {
  'id': 'sold-shirt',
  'userId': 'seller',
  'name': 'Cotton shirt',
  'description': 'A pre-loved cotton shirt.',
  'product_images': [AppImages.product1],
  'quality': 'Excellent',
  'size': 'M',
  'price': 2,
  'donation': 2,
  'securityFee': 1,
  'number': status == 'active' ? 1 : 0,
  'likes': 0,
  'postageSize': 'small',
  'status': ?status,
};

class _ListingApi extends UnexpectedApiService {
  _ListingApi(this.status);
  final Object? status;

  @override
  Future<Result<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    expect(endpoint, anyOf(ApiEndpoints.myProducts, ApiEndpoints.productWithDetailsById('sold-shirt')));
    return Result.success(
      {
            'success': true,
            'data': endpoint == ApiEndpoints.myProducts
                ? {
                    'products': [_listingJson(status)],
                  }
                : _listingJson(status),
            'meta': {'hasMore': false},
          }
          as T,
    );
  }
}

class _CheckoutRepository extends Fake implements ICheckoutRepository {}

class _DonationRepository extends Fake implements IDonationRepository {}

CheckoutViewModel _checkout(String? userId) => CheckoutViewModel(
  donationRepository: _DonationRepository(),
  checkoutRepository: _CheckoutRepository(),
  navigator: NavigationProvider(),
  currentUserIdProvider: () => userId,
);

void main() {
  for (final status in ['sold', 'active', 'unlisted', 'pending', null, 0]) {
    test('API status $status is retained without inferring sales from zero stock', () async {
      final api = _ListingApi(status);
      final products = await ProfileListingsRepository(api).fetchListings();
      final details = await ProductRepository(api).fetchProduct('sold-shirt');

      expect(products.isSuccess, isTrue);
      expect(details.isSuccess, isTrue);
      expect(products.value!.listings.single.isSold, status == 'sold');
      expect(details.value!.isSold, status == 'sold');
      expect(Product.fromJson(details.value!.toJson()).isSold, status == 'sold');
    });
  }

  test('a sold listing cannot enter the basket, while an active listing can', () {
    final checkout = _checkout('buyer');
    addTearDown(checkout.dispose);
    expect(checkout.addItem(Product.fromJson(_listingJson('sold'))), isFalse);
    expect(checkout.basketItems, isEmpty);
    expect(checkout.addItem(Product.fromJson(_listingJson('active'))), isTrue);
    expect(checkout.basketItems, hasLength(1));
  });

  test('sold strip has at least WCAG AA contrast for normal text', () {
    final contrast = (AppColors.white.computeLuminance() + 0.05) / (AppColors.soldGreen.computeLuminance() + 0.05);
    expect(contrast, greaterThanOrEqualTo(4.5));
  });

  testWidgets('small seller cards announce Sold and fit large text', (tester) async {
    final semantics = tester.ensureSemantics();
    final result = await ProfileListingsRepository(_ListingApi('sold')).fetchListings();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 138,
                child: SellerListingCard(listing: result.value!.listings.single),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.productSold), findsOneWidget);
    expect(find.bySemanticsLabel('Cotton shirt. £2.00. Sold.'), findsOneWidget);
    expect(tester.widget<Text>(find.text(AppStrings.productSold)).style!.fontWeight, FontWeight.w700);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('general product card displays Sold without changing its image height', (tester) async {
    final product = Product.fromJson(_listingJson('sold'));
    final viewModel = ProductViewModel(
      productRepository: ProductRepository(_ListingApi('sold')),
      navigator: NavigationProvider(),
      currentUserIdProvider: () => 'buyer',
    );
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 180, child: ProductCard(product: product)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.productSold), findsOneWidget);
    expect(find.text(AppStrings.productSoldCongratulations), findsNothing);
    final strip = tester.getRect(find.byType(SoldListingBanner));
    final photo = tester.getRect(find.byType(AspectRatio));
    expect(strip.bottom, photo.bottom);
    expect(strip.left, photo.left);
    expect(strip.right, photo.right);
    expect(tester.takeException(), isNull);
  });

  for (final userId in ['seller', 'buyer', null]) {
    for (final status in ['sold', 'active']) {
      testWidgets('$status detail page gives seller instructions only to the owner ($userId)', (tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final checkout = _checkout(userId);
        final products = ProductViewModel(
          productRepository: ProductRepository(_ListingApi(status)),
          navigator: NavigationProvider(),
          currentUserIdProvider: () => userId,
        );
        addTearDown(checkout.dispose);
        addTearDown(products.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<IEditListingRepository>.value(value: EditListingRepositoryStub()),
              ChangeNotifierProvider.value(value: checkout),
              ChangeNotifierProvider.value(value: products),
            ],
            child: const MaterialApp(home: ProductPage(productId: 'sold-shirt')),
          ),
        );
        await tester.pumpAndSettle();

        final isSold = status == 'sold';
        final isSeller = userId == 'seller';
        expect(find.text(AppStrings.productSold), isSold ? findsOneWidget : findsNothing);
        expect(find.text(AppStrings.productSoldCongratulations), isSold && isSeller ? findsOneWidget : findsNothing);
        expect(find.text(AppStrings.productSoldNextSteps), isSold && isSeller ? findsOneWidget : findsNothing);
        expect(find.text(AppStrings.productPageBuyNow), isSold || isSeller ? findsNothing : findsOneWidget);
        if (!isSold && isSeller) {
          await tester.tap(find.byTooltip('Manage Cotton shirt'));
          await tester.pumpAndSettle();
          expect(find.text('Edit listing'), findsOneWidget);
        } else {
          expect(find.byTooltip('Manage Cotton shirt'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('seller notice wraps at 320px and 200% text in $brightness mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(width: 320, child: SoldListingBanner(showSellerMessage: true)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.productSoldNextSteps), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
