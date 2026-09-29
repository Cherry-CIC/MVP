import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
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

class _ProductRepositoryStub extends ProductRepository {
  _ProductRepositoryStub() : super(const UnexpectedApiService());

  int likeCount = 0;

  @override
  Future<Result<ProductLikeUpdate>> likeProduct(Product product) async {
    likeCount += 1;
    return Result.success(
      ProductLikeUpdate(liked: true, likes: product.likes + 1),
    );
  }
}

void main() {
  testWidgets('ProductPage keeps seller details and hides buyer actions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigator = NavigationProvider();
    final repository = _ProductRepositoryStub();
    final productViewModel = ProductViewModel(
      productRepository: repository,
      navigator: navigator,
    )..setProduct(_product);
    final checkoutViewModel = CheckoutViewModel(
      donationRepository: _DonationRepositoryStub(),
      checkoutRepository: _CheckoutRepositoryStub(),
      navigator: navigator,
      currentUserIdProvider: () => 'seller-1',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider<ProductViewModel>.value(
            value: productViewModel,
          ),
          ChangeNotifierProvider<CheckoutViewModel>.value(
            value: checkoutViewModel,
          ),
        ],
        child: const MaterialApp(home: ProductPage()),
      ),
    );
    await tester.pump();

    expect(find.byType(BottomCta), findsNothing);
    expect(find.text(AppStrings.productPageBuyNow), findsNothing);
    expect(find.text(AppStrings.productPageYourListing), findsNothing);
    expect(find.text(AppStrings.productPageMakeOffer), findsNothing);
    expect(find.text(AppStrings.productPageRequestOtherCharity), findsNothing);
    expect(find.text(AppStrings.askSeller), findsNothing);
    expect(find.text(_product.name), findsOneWidget);
    expect(find.text(_product.description), findsOneWidget);
    expect(find.text(_product.size), findsOneWidget);
    expect(find.text(_product.quality), findsOneWidget);
    expect(find.text('£20.00'), findsNWidgets(2));
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_outline));
    await tester.pumpAndSettle();

    expect(repository.likeCount, 0);
    expect(productViewModel.isProductLiked(_product.id), isFalse);
    expect(find.text('0'), findsOneWidget);
    expect(checkoutViewModel.basketItems, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public product card retains likes and checkout navigation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigator = NavigationProvider();
    final repository = _ProductRepositoryStub();
    final productViewModel = ProductViewModel(
      productRepository: repository,
      navigator: navigator,
    );
    final checkoutViewModel = CheckoutViewModel(
      donationRepository: _DonationRepositoryStub(),
      checkoutRepository: _CheckoutRepositoryStub(),
      navigator: navigator,
      currentUserIdProvider: () => 'buyer-1',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
          ChangeNotifierProvider<CheckoutViewModel>.value(
            value: checkoutViewModel,
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigator.navigatorKey,
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.checkout) {
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Checkout route')),
              );
            }
            return AppRoutes.generateRoute(settings);
          },
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: ProductCard(
                product: _product,
                onTap: () => productViewModel.goToProductPage(_product),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(_product.name));
    await tester.pumpAndSettle();

    expect(find.byType(ProductPage), findsOneWidget);
    expect(productViewModel.product, same(_product));
    expect(find.text(_product.description), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, AppStrings.productPageBuyNow),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byIcon(Icons.favorite_outline));
    await tester.pumpAndSettle();

    expect(repository.likeCount, 1);
    expect(productViewModel.isProductLiked(_product.id), isTrue);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text(AppStrings.productPageBuyNow));
    await tester.pumpAndSettle();

    expect(checkoutViewModel.basketItems, [_product]);
    expect(find.text('Checkout route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _product = Product(
  id: 'product-1',
  userId: 'seller-1',
  name: 'Jumper',
  description: 'Blue jumper',
  quality: 'Good',
  productImages: [AppImages.product1],
  donation: 20,
  price: 20,
  securityFee: 2,
  likes: 0,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
);
