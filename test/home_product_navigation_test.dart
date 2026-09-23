import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/home/home_repository.dart' as home;
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/home_screen.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/unexpected_api_service.dart';

class _HomeRepositoryStub implements home.IHomeRepository {
  @override
  Future<Result<home.ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
  }) async {
    return Result.success(
      const home.ProductPage(
        products: [_firstProduct, _selectedProduct],
        limit: 20,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

class _ProductRepositoryStub extends ProductRepository {
  _ProductRepositoryStub() : super(const UnexpectedApiService());

  @override
  Future<Result<List<Product>>> fetchLikedProducts() async {
    return Result.success(const []);
  }
}

class _CheckoutRepositoryStub implements ICheckoutRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DonationRepositoryStub implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Home opens the selected listing and keeps buyer checkout working', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigator = NavigationProvider();
    final productViewModel = ProductViewModel(
      productRepository: _ProductRepositoryStub(),
      navigator: navigator,
      currentUserIdProvider: () => 'buyer-1',
    )..setProduct(_firstProduct);
    final checkoutViewModel = CheckoutViewModel(
      donationRepository: _DonationRepositoryStub(),
      checkoutRepository: _CheckoutRepositoryStub(),
      navigator: navigator,
      currentUserIdProvider: () => 'buyer-1',
    );
    final generatedRoutes = <String?>[];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider(create: (_) => SearchController()),
          ChangeNotifierProvider(
            create: (_) => HomeViewModel(homeRepository: _HomeRepositoryStub()),
          ),
          ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
          ChangeNotifierProvider<CheckoutViewModel>.value(value: checkoutViewModel),
        ],
        child: MaterialApp(
          navigatorKey: navigator.navigatorKey,
          onGenerateRoute: (settings) {
            generatedRoutes.add(settings.name);
            if (settings.name == AppRoutes.checkout) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('Checkout destination')),
              );
            }
            return AppRoutes.generateRoute(settings);
          },
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_selectedProduct.name));
    await tester.pumpAndSettle();

    expect(generatedRoutes, [AppRoutes.product]);
    expect(find.byType(ProductPage), findsOneWidget);
    expect(productViewModel.product, same(_selectedProduct));
    expect(find.text(_selectedProduct.name), findsOneWidget);
    expect(find.text(_selectedProduct.description), findsOneWidget);
    expect(find.text(_firstProduct.description), findsNothing);
    final buyButton = find.widgetWithText(FilledButton, AppStrings.productPageBuyNow);
    expect(tester.widget<FilledButton>(buyButton).onPressed, isNotNull);

    await tester.tap(buyButton);
    await tester.pumpAndSettle();

    expect(generatedRoutes, [AppRoutes.product, AppRoutes.checkout]);
    expect(find.text('Checkout destination'), findsOneWidget);
    expect(checkoutViewModel.basketItems, [same(_selectedProduct)]);
  });
}

const _firstProduct = Product(
  id: 'home-first-product',
  userId: 'seller-1',
  name: 'Green shirt',
  description: 'A green shirt from the first seller',
  quality: 'Good',
  productImages: [AppImages.product1],
  donation: 10,
  price: 11,
  securityFee: 1,
  likes: 0,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
);

const _selectedProduct = Product(
  id: 'home-selected-product',
  userId: 'seller-2',
  name: 'Blue jumper',
  description: 'A blue jumper from the selected seller',
  quality: 'Very good',
  productImages: [AppImages.product2],
  donation: 20,
  price: 22,
  securityFee: 2,
  likes: 3,
  number: 1,
  size: 'L',
  postageSizeId: 'small',
);
