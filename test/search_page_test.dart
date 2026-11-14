import 'dart:ui' show SemanticsAction;

import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/search/widgets/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

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
    return responses.isEmpty ? _page() : responses.removeAt(0);
  }
}

class _Categories implements ICategoryRepository {
  bool fail = false;
  int requests = 0;
  final removed = <String>{};
  @override
  Future<Result<List<Category>>> fetchCategories() async {
    requests++;
    return fail
        ? Result.failure('offline')
        : Result.success([
            for (final name in [
              'Women',
              'Men',
              'Children',
              'Accessories',
              'Unisex',
              'Designer',
              'Books',
              'Board Games',
              'Vinyl & Disk',
            ])
              if (!removed.contains(name))
                Category(
                  id: name.toLowerCase(),
                  name: name,
                  imageUrl: 'https://example.com/icon.png',
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
          ]);
  }
}

Result<ProductPage> _page({List<Product> products = const [], String? cursor}) => Result.success(
  ProductPage(products: products, limit: 20, nextCursor: cursor, hasMore: cursor != null),
);

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

Future<HomeViewModel> _open(
  WidgetTester tester,
  _Items items, {
  _Categories? categories,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool open = true,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = NavigationProvider();
  final model = HomeViewModel(homeRepository: items);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        ChangeNotifierProvider.value(value: model),
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
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          builder: (_) => Scaffold(appBar: AppBar(), body: Text('Opened ${settings.name}')),
        ),
        home: const Scaffold(body: Search(showAsBar: true)),
      ),
    ),
  );
  if (open) {
    await tester.tap(find.byType(Search));
    await tester.pumpAndSettle();
  }
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    model.dispose();
  });
  return model;
}

void main() {
  testWidgets('search entry point supports a screen reader tap action', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, _Items(), open: false);
    final node = tester.getSemantics(find.byType(Search));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('reopening search refreshes categories removed from the catalogue', (tester) async {
    final categories = _Categories();
    await _open(tester, _Items(), categories: categories);
    expect(find.text('Women'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    categories.removed.add('Women');
    await tester.tap(find.byType(Search));
    await tester.pumpAndSettle();
    expect(categories.requests, 2);
    expect(find.text('Women'), findsNothing);
    expect(find.text('Men'), findsOneWidget);
  });

  testWidgets('Charities opens Discover and returns to categories', (tester) async {
    await _open(tester, _Items());
    await tester.tap(find.text('Charities'));
    await tester.pumpAndSettle();
    expect(find.text('Opened ${AppRoutes.discover}'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Women'), findsOneWidget);
  });

  testWidgets('opening shows categories, typing searches, backspace restores browse and back exits', (tester) async {
    final items = _Items();
    final model = await _open(tester, items);
    expect(find.text('Women'), findsOneWidget);
    expect(find.text('Vinyl & Disk'), findsOneWidget);
    expect(find.text('Electronics'), findsNothing);
    expect(find.text('No items found'), findsNothing);
    expect(items.requests, isEmpty);
    await tester.enterText(find.byType(TextField), 'coat');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(items.requests.last.search, 'coat');
    expect(find.text('No items found'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Women'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage), findsNothing);
    expect(model.hasActiveSearch, isFalse);
  });

  testWidgets('category-only search and clear query preserve the category until cleared', (tester) async {
    final items = _Items()
      ..responses.addAll([
        _page(products: [_coat]),
        _page(products: [_coat]),
        _page(products: [_coat]),
      ]);
    final model = await _open(tester, items);
    await tester.tap(find.text('Women'));
    await tester.pumpAndSettle();
    expect(items.requests.last.categoryId, 'women');
    expect(find.text('Red coat'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus, isFalse);
    await tester.enterText(find.byType(TextField), 'coat');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(items.requests.last, (search: '', categoryId: 'women', cursor: null));
    expect(model.searchCategory!.name, 'Women');
    await tester.tap(find.byTooltip('Clear category'));
    await tester.pumpAndSettle();
    expect(find.text('Men'), findsOneWidget);
    expect(model.hasActiveSearch, isFalse);
  });

  testWidgets('swiping the list dismisses the keyboard and keeps search open', (tester) async {
    await _open(tester, _Items());
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus, isTrue);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 150));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus, isFalse);
    expect(find.byType(SearchPage), findsOneWidget);
    expect(find.text('Women'), findsOneWidget);
  });

  testWidgets('empty continuation pages retain load more and show retry feedback', (tester) async {
    final items = _Items()
      ..responses.addAll([
        _page(cursor: 'next'),
        Result.failure('offline'),
        _page(products: [_coat]),
      ]);
    await _open(tester, items);
    await tester.tap(find.text('Women'));
    await tester.pumpAndSettle();
    expect(find.text('No items found'), findsNothing);
    await tester.tap(find.text('Load more results'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load more items. Please try again.'), findsOneWidget);
    await tester.tap(find.text('Load more results'));
    await tester.pumpAndSettle();
    expect(find.text('Red coat'), findsOneWidget);
    expect(items.requests.last.cursor, 'next');
    expect(items.requests.last.categoryId, 'women');
  });

  testWidgets('category failure leaves text search available and category retry works', (tester) async {
    final categories = _Categories()..fail = true;
    final items = _Items()
      ..responses.addAll([
        Result.failure('offline'),
        _page(products: [_coat]),
      ]);
    await _open(tester, items, categories: categories);
    expect(find.text('Retry categories'), findsOneWidget);
    categories.fail = false;
    await tester.tap(find.text('Retry categories'));
    await tester.pumpAndSettle();
    expect(find.text('Women'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'coat');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry search'));
    await tester.pumpAndSettle();
    expect(find.text('Red coat'), findsOneWidget);
  });

  testWidgets('listing navigation returns to the same search', (tester) async {
    final items = _Items()..responses.add(_page(products: [_coat]));
    final model = await _open(tester, items);
    await tester.tap(find.text('Women'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Red coat'));
    await tester.pumpAndSettle();
    expect(find.text('Opened ${AppRoutes.product}'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Red coat'), findsOneWidget);
    expect(model.searchCategory!.name, 'Women');
  });

  testWidgets('categories remain usable with large text and dark mode', (tester) async {
    await _open(tester, _Items(), brightness: Brightness.dark, textScale: 2);
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Vinyl & Disk'), findsOneWidget);
  });
}
