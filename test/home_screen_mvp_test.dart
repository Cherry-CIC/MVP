import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/discover_button.dart';
import 'package:cherry_mvp/features/home/widgets/home_screen.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/search/widgets/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

class _HomeRepositoryStub implements IHomeRepository {
  _HomeRepositoryStub(this.result, {this.onFetch});

  final Result<ProductPage> result;
  final Result<ProductPage> Function(String? categoryId)? onFetch;
  final requestedCategoryIds = <String?>[];

  @override
  Future<Result<ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
    String? categoryId,
  }) async {
    requestedCategoryIds.add(categoryId);
    return onFetch?.call(categoryId) ?? result;
  }
}

class _CategoryRepositoryStub implements ICategoryRepository {
  _CategoryRepositoryStub(this.categories);

  final List<Category> categories;

  @override
  Future<Result<List<Category>>> fetchCategories() async {
    return Result.success(categories);
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

Future<({ProductViewModel productViewModel, _HomeRepositoryStub homeRepository})> _pumpHomeScreen(
  WidgetTester tester, {
  List<Product> products = const [],
  List<Product> likedProducts = const [],
  List<Category> categories = const [],
  Result<ProductPage>? fetchResult,
  Result<ProductPage> Function(String? categoryId)? onFetch,
  EdgeInsets mediaPadding = EdgeInsets.zero,
  VoidCallback? onOpenDiscover,
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
  final homeRepository = _HomeRepositoryStub(result, onFetch: onFetch);
  final productViewModel = ProductViewModel(
    productRepository: _ProductRepositoryStub(likedProducts),
    navigator: navigator,
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) => HomeViewModel(homeRepository: homeRepository),
        ),
        ChangeNotifierProvider<CategoryViewModel>(
          create: (_) => CategoryViewModel(
            categoryRepository: _CategoryRepositoryStub(categories),
            navigator: navigator,
          ),
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
          child: HomeScreen(onOpenDiscover: onOpenDiscover),
        ),
      ),
    ),
  );

  return (productViewModel: productViewModel, homeRepository: homeRepository);
}

Category _category(String id, String name) => Category(
  id: id,
  name: name,
  imageUrl: '',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

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
  testWidgets('HomeScreen shows the slimmer global search bar', (tester) async {
    await _pumpHomeScreen(tester);

    expect(find.text('Find something special...'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets(
    'HomeScreen keeps the search bar and discover tile cleanly below the top safe area',
    (tester) async {
      await _pumpHomeScreen(
        tester,
        mediaPadding: const EdgeInsets.only(top: 32),
      );

      final searchTop = tester.getTopLeft(find.byType(Search)).dy;
      final searchBottom = tester.getBottomLeft(find.byType(Search)).dy;
      final discoverTop = tester.getTopLeft(find.byType(DiscoverButton)).dy;

      expect(searchTop, 36);
      expect(discoverTop, greaterThan(searchBottom));
    },
  );

  testWidgets('HomeScreen shows category pills below search without Charities and filters Home items', (tester) async {
    final women = _category('women', 'Women');
    final men = _category('men', 'Men');
    final allProduct = _product(1);
    final womenProduct = _product(2);

    final pumped = await _pumpHomeScreen(
      tester,
      categories: [women, men],
      onFetch: (categoryId) {
        if (categoryId == 'women') {
          return Result.success(
            ProductPage(products: [womenProduct], limit: 20, nextCursor: null, hasMore: false),
          );
        }
        if (categoryId == 'men') {
          return Result.success(
            const ProductPage(products: [], limit: 20, nextCursor: null, hasMore: false),
          );
        }
        return Result.success(
          ProductPage(products: [allProduct], limit: 20, nextCursor: null, hasMore: false),
        );
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Women'), findsOneWidget);
    expect(find.text('Men'), findsOneWidget);
    expect(find.text('Charities'), findsNothing);
    expect(find.text('MVP item 1'), findsOneWidget);

    await tester.tap(find.text('Women'));
    await tester.pumpAndSettle();

    expect(pumped.homeRepository.requestedCategoryIds.last, 'women');
    expect(find.text('MVP item 2'), findsOneWidget);
    expect(find.text('MVP item 1'), findsNothing);

    await tester.tap(find.text('Men'));
    await tester.pumpAndSettle();

    expect(find.text('No items in Men yet'), findsOneWidget);
    await tester.tap(find.text('Show all items'));
    await tester.pumpAndSettle();

    expect(pumped.homeRepository.requestedCategoryIds.last, isNull);
    expect(find.text('MVP item 1'), findsOneWidget);
  });

  testWidgets('HomeScreen hides search bar and category pills when scrolling down and reveals them on scroll up', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHomeScreen(
      tester,
      categories: [_category('women', 'Women'), _category('men', 'Men')],
      products: List.generate(12, (index) => _product(index + 1)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Search), findsOneWidget);
    expect(find.text('Women'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.byType(Search), findsNothing);
    expect(find.text('Women'), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 250));
    await tester.pumpAndSettle();

    expect(find.byType(Search), findsOneWidget);
    expect(find.text('Women'), findsOneWidget);
  });

  testWidgets('scrolling horizontal category pills does not trigger vertical feed pagination', (tester) async {
    final categories = [
      for (final name in ['Women', 'Men', 'Children', 'Accessories', 'Unisex', 'Designer', 'Books', 'Board Games'])
        _category(name.toLowerCase(), name),
    ];
    final pumped = await _pumpHomeScreen(
      tester,
      categories: categories,
      fetchResult: Result.success(
        ProductPage(
          products: List.generate(4, (index) => _product(index + 1)),
          limit: 20,
          nextCursor: 'cursor-2',
          hasMore: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initialRequests = pumped.homeRepository.requestedCategoryIds.length;

    await tester.drag(find.byType(SingleChildScrollView), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(pumped.homeRepository.requestedCategoryIds.length, initialRequests);
  });

  testWidgets('HomeScreen hides charity advert placeholders for the MVP', (tester) async {
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

  testWidgets('HomeScreen shows product load errors on fetch failure', (tester) async {
    await _pumpHomeScreen(
      tester,
      fetchResult: Result.failure('technical failure'),
    );
    await tester.pump();

    expect(find.text(AppStrings.failedToLoadProducts), findsOneWidget);
    expect(find.text('technical failure'), findsOneWidget);
    expect(find.text(AppStrings.noProductsAvailable), findsNothing);
  });

  testWidgets('HomeScreen restores liked hearts from the API', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final product = _product(1);
    final pumped = await _pumpHomeScreen(
      tester,
      products: [product],
      likedProducts: [product],
    );
    await tester.pumpAndSettle();

    expect(pumped.productViewModel.isProductLiked(product.id), isTrue);
  });
}
