import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/liked_items/liked_items_page.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

class _FakeProductRepository extends ProductRepository {
  _FakeProductRepository({
    required this.fetchResult,
    this.unlikeResult,
  }) : super(const UnexpectedApiService());

  Result<List<Product>> fetchResult;
  Result<void>? unlikeResult;
  int fetchCount = 0;

  @override
  Future<Result<void>> likeProduct(Product product) async {
    return Result.success(null);
  }

  @override
  Future<Result<List<Product>>> fetchLikedProducts() async {
    fetchCount += 1;
    return fetchResult;
  }

  @override
  Future<Result<void>> unlikeProduct(String productId) async {
    return unlikeResult ?? Result.success(null);
  }
}

Product _product({String id = 'liked-product', String name = 'Liked jacket'}) {
  return Product(
    id: id,
    name: name,
    description: 'A liked test product',
    quality: 'Good',
    productImages: const [AppImages.product1],
    donation: 6,
    price: 7,
    securityFee: 1,
    likes: 0,
    number: 1,
    size: 'M',
    postageSizeId: 'small',
  );
}

Future<void> _pumpLikedItemsPage(
  WidgetTester tester, {
  required _FakeProductRepository repository,
}) async {
  final navigator = NavigationProvider();
  final productViewModel = ProductViewModel(
    productRepository: repository,
    navigator: navigator,
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        Provider<ProductRepository>.value(value: repository),
        ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
      ],
      child: MaterialApp(
        navigatorKey: navigator.navigatorKey,
        onGenerateRoute: AppRoutes.generateRoute,
        home: const LikedItemsPage(),
      ),
    ),
  );
}

void main() {
  testWidgets('LikedItemsPage shows an empty state', (tester) async {
    await _pumpLikedItemsPage(
      tester,
      repository: _FakeProductRepository(
        fetchResult: Result.success(const <Product>[]),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.likedItemsTitle), findsOneWidget);
    expect(find.text(AppStrings.likedItemsEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.likedItemsBrowseProducts), findsOneWidget);
  });

  testWidgets('LikedItemsPage shows an error state and retry action', (
    tester,
  ) async {
    final repository = _FakeProductRepository(
      fetchResult: Result.failure(AppStrings.likedItemsLoadError),
    );

    await _pumpLikedItemsPage(tester, repository: repository);
    await tester.pump();

    expect(find.text(AppStrings.likedItemsLoadError), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);

    repository.fetchResult = Result.success(const <Product>[]);
    await tester.tap(find.text(AppStrings.retry));
    await tester.pump();

    expect(repository.fetchCount, 2);
    expect(find.text(AppStrings.likedItemsEmptyTitle), findsOneWidget);
  });

  testWidgets('LikedItemsPage displays liked product cards', (tester) async {
    await _pumpLikedItemsPage(
      tester,
      repository: _FakeProductRepository(
        fetchResult: Result.success([_product()]),
      ),
    );
    await tester.pump();

    expect(find.byType(ProductCard), findsOneWidget);
    expect(find.text('Liked jacket'), findsOneWidget);
    expect(find.byKey(const ValueKey('product-like-liked-product')), findsOneWidget);
  });

  testWidgets('tapping a liked product opens the existing product page', (
    tester,
  ) async {
    await _pumpLikedItemsPage(
      tester,
      repository: _FakeProductRepository(
        fetchResult: Result.success([_product()]),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(ProductCard));
    await tester.pumpAndSettle();

    expect(find.byType(ProductPage), findsOneWidget);
  });

  testWidgets('unliking a product removes its card after success', (
    tester,
  ) async {
    await _pumpLikedItemsPage(
      tester,
      repository: _FakeProductRepository(
        fetchResult: Result.success([_product()]),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('product-like-liked-product')));
    await tester.pumpAndSettle();

    expect(find.text('Liked jacket'), findsNothing);
    expect(find.text(AppStrings.likedItemsEmptyTitle), findsOneWidget);
  });

  testWidgets('failed unlike keeps the product card visible', (tester) async {
    await _pumpLikedItemsPage(
      tester,
      repository: _FakeProductRepository(
        fetchResult: Result.success([_product()]),
        unlikeResult: Result.failure('Unlike failed'),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('product-like-liked-product')));
    await tester.pumpAndSettle();

    expect(find.text('Liked jacket'), findsOneWidget);
  });
}
