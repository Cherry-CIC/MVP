import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_repository.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/widgets/product_information.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/shared_widgets/bottom_cta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/unexpected_api_service.dart';

// These legacy fixtures have no edit version and cannot open the editor.
class _EditListingRepositoryStub implements IEditListingRepository {
  @override
  bool canEdit(Product product) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected listing edit');
}

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
  Future<Result<Product>> fetchProduct(String productId) async => Result.success(_product);

  @override
  Future<Result<ProductLikeUpdate>> likeProduct(Product product) async {
    likeCount += 1;
    return Result.success(
      ProductLikeUpdate(liked: true, likes: product.likes + 1),
    );
  }
}

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('product details fit width $width at text scale $scale', (tester) async {
        final fontLoader = FontLoader('Raleway')
          ..addFont(rootBundle.load('assets/fonts/Raleway-ExtraBold.ttf'));
        await fontLoader.load();
        final priceFontLoader = FontLoader('InstrumentSansPricing')
          ..addFont(rootBundle.load('assets/fonts/InstrumentSans-Bold.ttf'));
        await priceFontLoader.load();
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final viewModel = ProductViewModel(
          productRepository: _ProductRepositoryStub(),
          navigator: NavigationProvider(),
        );
        addTearDown(viewModel.dispose);
        const product = Product(
          id: 'layout-product',
          description: 'Layout test',
          productImages: [],
          securityFee: 2,
          likes: 0,
          number: 1,
          postageSizeId: 'small',
          name: 'Long sleeve cotton jumper with embroidered detail',
          size: 'XXXL',
          quality: 'EXCELLENT',
          donation: 1234.56,
          price: 1234.56,
        );
        await tester.pumpWidget(
          ChangeNotifierProvider<ProductViewModel>.value(
            value: viewModel,
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(body: ProductInformation(product: product)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final label in [product.name, product.size, product.quality, '£1234.56']) {
          for (final element in find.text(label).evaluate()) {
            final rect = tester.getRect(find.byWidget(element.widget));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(width));
          }
          expect(find.text(label), findsWidgets);
        }
      });
    }
  }

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
          Provider<IEditListingRepository>(create: (_) => _EditListingRepositoryStub()),
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
          Provider<IEditListingRepository>(create: (_) => _EditListingRepositoryStub()),
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
