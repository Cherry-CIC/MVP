import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/discover/discover_page.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/discover/discover_viewmodel.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/search/widgets/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

class _CharityLikeProductRepository extends ProductRepository {
  _CharityLikeProductRepository({
    this.initialCharities = const [],
    this.initialLikedCharities = const [],
  }) : super(const UnexpectedApiService());

  final List<Charity> initialCharities;
  final List<Charity> initialLikedCharities;
  final Map<String, int> _likesById = {};

  @override
  Future<Result<List<Charity>>> fetchCharities() async {
    for (final charity in initialCharities) {
      _likesById[charity.id] = charity.likes;
    }
    return Result.success(initialCharities);
  }

  @override
  Future<Result<List<Charity>>> fetchLikedCharities() async {
    for (final charity in initialLikedCharities) {
      _likesById[charity.id] = charity.likes;
    }
    return Result.success(initialLikedCharities);
  }

  @override
  Future<Result<CharityLikeUpdate>> likeCharity(Charity charity) async {
    final nextLikes = (_likesById[charity.id] ?? charity.likes) + 1;
    _likesById[charity.id] = nextLikes;
    return Result.success(
      CharityLikeUpdate(
        liked: true,
        likes: nextLikes,
        charity: charity.copyWith(likes: nextLikes),
      ),
    );
  }

  @override
  Future<Result<CharityLikeUpdate>> unlikeCharity(String charityId) async {
    final current = _likesById[charityId] ?? 1;
    final nextLikes = current > 0 ? current - 1 : 0;
    _likesById[charityId] = nextLikes;
    return Result.success(
      CharityLikeUpdate(liked: false, likes: nextLikes),
    );
  }
}

class _Items implements IHomeRepository {
  final requests = <({String? search, String? categoryId, String? cursor})>[];
  final responses = <Result<ProductPage>>[];

  @override
  Future<Result<ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
    String? categoryId,
  }) async {
    requests.add((search: search, categoryId: categoryId, cursor: cursor));
    return responses.isEmpty
        ? Result.success(const ProductPage(products: [], limit: 20, nextCursor: null, hasMore: false))
        : responses.removeAt(0);
  }
}

class _Categories implements ICategoryRepository {
  bool fail = false;
  int requests = 0;
  final removed = <String>{};

  @override
  Future<Result<List<Category>>> fetchCategories() async {
    requests++;
    if (fail) return Result.failure('offline');
    return Result.success([
      for (final name in ['Women', 'Men', 'Children', 'Accessories', 'Books', 'Vinyl & Disk'])
        if (!removed.contains(name))
          Category(
            id: name.toLowerCase(),
            name: name,
            imageUrl: '',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
    ]);
  }
}

final _coat = Product(
  id: 'coat',
  name: 'Red coat',
  description: '',
  quality: 'GOOD',
  productImages: const [],
  donation: 5,
  price: 5,
  securityFee: 1,
  likes: 0,
  number: 1,
  size: 'Medium',
  postageSizeId: 'small',
);

Future<void> _pumpDiscover(
  WidgetTester tester, {
  _Items? items,
  _Categories? categories,
  bool showBackButton = false,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final navigator = NavigationProvider();
  final home = HomeViewModel(homeRepository: items ?? _Items());
  addTearDown(home.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        ChangeNotifierProvider(create: (_) => DiscoverViewModel(discoverRepository: DiscoverRepository())),
        ChangeNotifierProvider.value(value: home),
        ChangeNotifierProvider(
          create: (_) => CategoryViewModel(categoryRepository: categories ?? _Categories(), navigator: navigator),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductViewModel(
            productRepository: ProductRepository(const UnexpectedApiService()),
            navigator: navigator,
          ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigator.navigatorKey,
        theme: buildTheme(brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: DiscoverPage(showBackButton: showBackButton),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Discover opens on Popular with a search bar and no back arrow as a tab', (tester) async {
    await _pumpDiscover(tester);

    expect(find.byType(Search), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Smaller Charities'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Local to you'), findsNothing);
    expect(find.text('Women'), findsNothing);
  });

  testWidgets('Discover shows a back arrow when opened as its own route', (tester) async {
    final navigator = NavigationProvider();
    final home = HomeViewModel(homeRepository: _Items());
    addTearDown(home.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider(create: (_) => DiscoverViewModel(discoverRepository: DiscoverRepository())),
          ChangeNotifierProvider.value(value: home),
          ChangeNotifierProvider(
            create: (_) => CategoryViewModel(categoryRepository: _Categories(), navigator: navigator),
          ),
          ChangeNotifierProvider(
            create: (_) => ProductViewModel(
              productRepository: ProductRepository(const UnexpectedApiService()),
              navigator: navigator,
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigator.navigatorKey,
          theme: buildTheme(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const DiscoverPage(showBackButton: true)),
              ),
              child: const Text('Open Discover'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Discover'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('search bar on Discover opens search', (tester) async {
    await _pumpDiscover(tester);

    await tester.tap(find.byType(Search));
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsOneWidget);
  });

  testWidgets('Categories tab lists catalogue categories without Charities and opens filtered search', (tester) async {
    final items = _Items()
      ..responses.add(Result.success(ProductPage(products: [_coat], limit: 20, nextCursor: null, hasMore: false)));
    final categories = _Categories();
    await _pumpDiscover(tester, items: items, categories: categories);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    expect(categories.requests, 1);
    expect(find.text('Charities'), findsNothing);
    expect(find.text('Women'), findsOneWidget);
    expect(find.text('Vinyl & Disk'), findsOneWidget);

    await tester.tap(find.text('Women'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsOneWidget);
    expect(items.requests.last.categoryId, 'women');
    expect(find.text('Red coat'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus, isFalse);
  });

  testWidgets('returning from category search clears it and keeps Categories selected', (tester) async {
    final items = _Items();
    await _pumpDiscover(tester, items: items);
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Men'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsNothing);
    expect(find.text('Men'), findsOneWidget);
    expect(tester.element(find.byType(DiscoverPage)).read<HomeViewModel>().hasActiveSearch, isFalse);
  });

  testWidgets('switching back to Popular shows charities again', (tester) async {
    await _pumpDiscover(tester);
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Women'), findsOneWidget);

    await tester.tap(find.text('Popular'));
    await tester.pumpAndSettle();

    expect(find.text('Women'), findsNothing);
    expect(find.byType(CustomScrollView), findsOneWidget);
  });

  testWidgets('categories refresh on each visit so removed ones disappear', (tester) async {
    final categories = _Categories();
    await _pumpDiscover(tester, categories: categories);
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Women'), findsOneWidget);

    await tester.tap(find.text('Popular'));
    await tester.pumpAndSettle();
    categories.removed.add('Women');
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    expect(categories.requests, 2);
    expect(find.text('Women'), findsNothing);
    expect(find.text('Men'), findsOneWidget);
  });

  testWidgets('category failure shows retry even after a previous successful load', (tester) async {
    final categories = _Categories();
    await _pumpDiscover(tester, categories: categories);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Women'), findsOneWidget);

    await tester.tap(find.text('Popular'));
    await tester.pumpAndSettle();

    categories.fail = true;
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Women'), findsNothing);
    expect(find.text('Retry categories'), findsOneWidget);

    categories.fail = false;
    await tester.tap(find.text('Retry categories'));
    await tester.pumpAndSettle();
    expect(find.text('Women'), findsOneWidget);
  });

  testWidgets('Categories stay usable with large text and dark mode', (tester) async {
    await _pumpDiscover(tester, brightness: Brightness.dark, textScale: 2);
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Vinyl & Disk'), findsOneWidget);
  });

  testWidgets('liking and unliking a charity on Discover updates the heart, count, and liked charities list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigator = NavigationProvider();
    final home = HomeViewModel(homeRepository: _Items());
    addTearDown(home.dispose);
    final productRepository = _CharityLikeProductRepository(
      initialCharities: [
        Charity(
          id: 'ca6tjKqCRurG0hB49Dcp',
          name: 'Water Aid',
          imageUrl: '',
          likes: 0,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      ],
    );
    final productViewModel = ProductViewModel(
      productRepository: productRepository,
      navigator: navigator,
    );
    addTearDown(productViewModel.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider(
            create: (_) => DiscoverViewModel(discoverRepository: DiscoverRepository()),
          ),
          ChangeNotifierProvider.value(value: home),
          ChangeNotifierProvider(
            create: (_) => CategoryViewModel(
              categoryRepository: _Categories(),
              navigator: navigator,
            ),
          ),
          ChangeNotifierProvider.value(value: productViewModel),
        ],
        child: MaterialApp(
          navigatorKey: navigator.navigatorKey,
          theme: buildTheme(),
          home: const DiscoverPage(showBackButton: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final waterAidLikeButton = find.byKey(
      const ValueKey('discover-charity-like-WaterAid'),
    );
    expect(waterAidLikeButton, findsOneWidget);
    expect(
      find.descendant(
        of: waterAidLikeButton,
        matching: find.byIcon(Icons.favorite_border),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: waterAidLikeButton, matching: find.text('0')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: waterAidLikeButton, matching: find.text('3')),
      findsNothing,
    );

    await tester.tap(waterAidLikeButton);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: waterAidLikeButton,
        matching: find.byIcon(Icons.favorite),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: waterAidLikeButton, matching: find.text('1')),
      findsOneWidget,
    );
    expect(productViewModel.cachedLikedCharities, hasLength(1));
    expect(
      productViewModel.cachedLikedCharities.first.id,
      'ca6tjKqCRurG0hB49Dcp',
    );

    await tester.tap(waterAidLikeButton);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: waterAidLikeButton,
        matching: find.byIcon(Icons.favorite_border),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: waterAidLikeButton, matching: find.text('0')),
      findsOneWidget,
    );
    expect(productViewModel.cachedLikedCharities, isEmpty);
  });
}
