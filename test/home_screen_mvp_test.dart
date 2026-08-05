import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/discover_button.dart';
import 'package:cherry_mvp/features/home/widgets/home_screen.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

class _HomeRepositoryStub implements IHomeRepository {
  _HomeRepositoryStub(this.result);

  final Result<ProductPage> result;

  @override
  Future<Result<ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
  }) async {
    return result;
  }
}

class _ProductRepositoryStub extends ProductRepository {
  _ProductRepositoryStub(this.likedProducts) : super(const UnexpectedApiService());

  final List<Product> likedProducts;

  @override
  Future<Result<List<Product>>> fetchLikedProducts() async {
    return Result.success(likedProducts);
  }
}

Future<ProductViewModel> _pumpHomeScreen(
  WidgetTester tester, {
  List<Product> products = const [],
  List<Product> likedProducts = const [],
  Result<ProductPage>? fetchResult,
  EdgeInsets mediaPadding = EdgeInsets.zero,
}) async {
  final navigator = NavigationProvider();
  final result =
      fetchResult ??
      Result.success(
        ProductPage(
          products: products,
          limit: 20,
          nextCursor: null,
          hasMore: false,
        ),
      );
  final productViewModel = ProductViewModel(
    productRepository: _ProductRepositoryStub(likedProducts),
    navigator: navigator,
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        ChangeNotifierProvider(create: (_) => SearchController()),
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) => HomeViewModel(homeRepository: _HomeRepositoryStub(result)),
        ),
        ChangeNotifierProvider<ProductViewModel>.value(
          value: productViewModel,
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData.fromView(tester.view).copyWith(
            padding: mediaPadding,
          ),
          child: const HomeScreen(),
        ),
      ),
    ),
  );

  return productViewModel;
}

Product _product(int index) {
  return Product(
    id: 'mvp-product-$index',
    name: 'MVP item $index',
    description: 'Test product',
    quality: 'Good',
    productImages: const [AppImages.product1],
    donation: 6,
    price: 7,
    securityFee: 1,
    likes: 0,
    number: index,
    size: 'M',
    postageSizeId: 'small',
  );
}

void main() {
  testWidgets('HomeScreen shows the global search bar', (
    tester,
  ) async {
    await _pumpHomeScreen(tester);

    expect(find.text('AI Search: Red Polka Dot Dress'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets(
    'HomeScreen keeps the discover tile below the top safe area for the MVP',
    (tester) async {
      await _pumpHomeScreen(
        tester,
        mediaPadding: const EdgeInsets.only(top: 32),
      );

      final discoverTop = tester.getTopLeft(find.byType(DiscoverButton)).dy;

      expect(discoverTop, 108);
    },
  );

  testWidgets('HomeScreen hides charity advert placeholders for the MVP', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHomeScreen(
      tester,
      products: List.generate(6, (index) => _product(index + 1)),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('MVP item 1'), findsOneWidget);
    expect(find.text(AppStrings.adText), findsNothing);
  });

  testWidgets('HomeScreen shows product load errors on fetch failure', (
    tester,
  ) async {
    await _pumpHomeScreen(
      tester,
      fetchResult: Result.failure('technical failure'),
    );
    await tester.pump();

    expect(find.text(AppStrings.failedToLoadProducts), findsOneWidget);
    expect(find.text('technical failure'), findsOneWidget);
    expect(find.text(AppStrings.noProductsAvailable), findsNothing);
  });

  testWidgets('HomeScreen restores liked hearts from the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final product = _product(1);
    final productViewModel = await _pumpHomeScreen(
      tester,
      products: [product],
      likedProducts: [product],
    );
    await tester.pumpAndSettle();

    expect(productViewModel.isProductLiked(product.id), isTrue);
  });
}
