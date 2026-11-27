import 'dart:ui' show SemanticsAction;

import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/search/charity_search.dart';
import 'package:cherry_mvp/features/search/recent_searches_store.dart';
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

class _Charities implements ICharityRepository {
  _Charities(this.charities);

  final List<Charity> charities;
  int fetchCalls = 0;

  @override
  Future<Result<List<Charity>>> fetchCharities() async {
    fetchCalls++;
    return Result.success(charities);
  }
}

Result<ProductPage> _page({List<Product> products = const [], String? cursor}) => Result.success(
  ProductPage(products: products, limit: 20, nextCursor: cursor, hasMore: cursor != null),
);

final _women = Category(
  id: 'women',
  name: 'Women',
  imageUrl: '',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
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
  RecentSearchesStore? recentSearchesStore,
  ICharityRepository? charityRepository,
  ValueChanged<RouteSettings>? onRoutePushed,
  Category? initialCategory,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool open = true,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = NavigationProvider();
  final discoverRepository = DiscoverRepository();
  final model = HomeViewModel(
    homeRepository: items,
    recentSearchesStore: recentSearchesStore ?? RecentSearchesStore.inMemory(),
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        Provider<DiscoverRepository>.value(value: discoverRepository),
        Provider<CharitySearch>(
          create: (_) => CharitySearch(discoverRepository: discoverRepository),
        ),
        if (charityRepository != null)
          ChangeNotifierProvider<CharityViewModel>(
            create: (_) => CharityViewModel(
              charityRepository: charityRepository,
              navigator: navigator,
            ),
          ),
        ChangeNotifierProvider.value(value: model),
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
        onGenerateRoute: (settings) {
          onRoutePushed?.call(settings);
          return MaterialPageRoute<void>(
            builder: (_) => Scaffold(appBar: AppBar(), body: Text('Opened ${settings.name}')),
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Search(showAsBar: true),
                if (initialCategory != null)
                  TextButton(
                    onPressed: () => openSearch(context, initialCategory: initialCategory),
                    child: const Text('Open category'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  if (open) {
    await tester.tap(initialCategory == null ? find.byType(Search) : find.text('Open category'));
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

  testWidgets('opening search without history shows clean empty prompt and no categories list', (tester) async {
    final items = _Items();
    final model = await _open(tester, items);

    expect(find.text('Search for anything'), findsOneWidget);
    expect(find.text('Charities'), findsNothing);
    expect(find.text('Women'), findsNothing);
    expect(find.text('No items found'), findsNothing);
    expect(items.requests, isEmpty);
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus, isTrue);

    await tester.enterText(find.byType(TextField), 'coat');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(items.requests.last.search, 'coat');
    expect(find.text('No items found'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Search for anything'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage), findsNothing);
    expect(model.hasActiveSearch, isFalse);
  });

  testWidgets('submitted searches are remembered on reopen, re-run on tap, and can be removed or cleared', (
    tester,
  ) async {
    final store = RecentSearchesStore.inMemory();
    final items = _Items()
      ..responses.addAll([
        _page(products: [_coat]),
        _page(products: [_coat]),
      ]);
    await _open(tester, items, recentSearchesStore: store);

    await tester.enterText(find.byType(TextField), 'red coat');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Red coat'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Search));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('red coat'), findsOneWidget);

    await tester.tap(find.text('red coat'));
    await tester.pumpAndSettle();
    expect(items.requests.last.search, 'red coat');
    expect(find.text('Red coat'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove recent search'));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsNothing);
    expect(find.text('Search for anything'), findsOneWidget);
  });

  testWidgets('tapping a search result saves the search query and Clear all empties history', (tester) async {
    final store = RecentSearchesStore.inMemory();
    await store.add('boots');
    final items = _Items()..responses.add(_page(products: [_coat]));
    await _open(tester, items, recentSearchesStore: store);

    await tester.enterText(find.byType(TextField), 'coat');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Red coat'));
    await tester.pumpAndSettle();
    expect(find.text('Opened ${AppRoutes.product}'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('coat'), findsOneWidget);
    expect(find.text('boots'), findsOneWidget);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('Search for anything'), findsOneWidget);
  });

  testWidgets('category-filtered search and clear query preserve the category until cleared', (tester) async {
    final items = _Items()
      ..responses.addAll([
        _page(products: [_coat]),
        _page(products: [_coat]),
        _page(products: [_coat]),
      ]);
    final model = await _open(tester, items, initialCategory: _women);

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
    expect(find.text('Search for anything'), findsOneWidget);
    expect(model.hasActiveSearch, isFalse);
  });

  testWidgets('swiping the list dismisses the keyboard and keeps search open', (tester) async {
    await _open(tester, _Items());
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus, isTrue);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 150));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus, isFalse);
    expect(find.byType(SearchPage), findsOneWidget);
    expect(find.text('Search for anything'), findsOneWidget);
  });

  testWidgets('empty continuation pages retain load more and show retry feedback', (tester) async {
    final items = _Items()
      ..responses.addAll([
        _page(cursor: 'next'),
        Result.failure('offline'),
        _page(products: [_coat]),
      ]);
    await _open(tester, items, initialCategory: _women);
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

  testWidgets('search failure supports retry and listing navigation returns to the same search', (tester) async {
    final items = _Items()
      ..responses.addAll([
        Result.failure('offline'),
        _page(products: [_coat]),
      ]);
    final model = await _open(tester, items, initialCategory: _women);
    expect(find.text('Retry search'), findsOneWidget);
    await tester.tap(find.text('Retry search'));
    await tester.pumpAndSettle();
    expect(find.text('Red coat'), findsOneWidget);

    await tester.tap(find.text('Red coat'));
    await tester.pumpAndSettle();
    expect(find.text('Opened ${AppRoutes.product}'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Red coat'), findsOneWidget);
    expect(model.searchCategory!.name, 'Women');
  });

  testWidgets('recent searches and empty prompt remain usable with large text and dark mode', (tester) async {
    final store = RecentSearchesStore.inMemory();
    await store.add('vintage wool jacket');
    await _open(
      tester,
      _Items(),
      recentSearchesStore: store,
      brightness: Brightness.dark,
      textScale: 2,
    );
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('vintage wool jacket'), findsOneWidget);
  });

  testWidgets('search bar and input display Find something special...', (tester) async {
    await _open(tester, _Items(), open: false);
    expect(find.text('Find something special...'), findsOneWidget);

    await tester.tap(find.byType(Search));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, 'Find something special...');
    expect(find.text('Find pre-loved items and charities across Cherry.'), findsOneWidget);
  });

  testWidgets('searching "water aid" shows WaterAid, records recent search, and opens CharityProfilePage', (
    tester,
  ) async {
    final store = RecentSearchesStore.inMemory();
    final pushed = <RouteSettings>[];
    await _open(
      tester,
      _Items(),
      recentSearchesStore: store,
      onRoutePushed: pushed.add,
    );

    await tester.enterText(find.byType(TextField), 'water aid');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Charities'), findsOneWidget);
    expect(find.text('WaterAid'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('No items found'), findsOneWidget);
    expect(find.text('Try different words.'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/images/search/empty_background.png',
      ),
      findsNothing,
    );

    await tester.tap(find.text('WaterAid'));
    await tester.pumpAndSettle();

    expect(find.text('Opened ${AppRoutes.charityProfile}'), findsOneWidget);
    expect(pushed.last.name, AppRoutes.charityProfile);
    final args = pushed.last.arguments as CharityProfileArgs;
    expect(args.charityId, 'ca6tjKqCRurG0hB49Dcp');
    expect(args.charityName, 'WaterAid');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('WaterAid'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('water aid'), findsOneWidget);
  });

  testWidgets('unified search renders matching charities above matching items', (tester) async {
    final bottle = Product(
      id: 'bottle',
      name: 'Water bottle',
      description: '',
      quality: 'NEW',
      productImages: const [],
      donation: 4,
      price: 4,
      securityFee: 1,
      likes: 0,
      number: 1,
      size: 'One size',
      postageSizeId: 'small',
    );
    final items = _Items()..responses.add(_page(products: [bottle]));
    await _open(tester, items);

    await tester.enterText(find.byType(TextField), 'water');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Charities'), findsOneWidget);
    expect(find.text('WaterAid'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Water bottle'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('WaterAid')).dy,
      lessThan(tester.getTopLeft(find.text('Water bottle')).dy),
    );
  });

  testWidgets('category-filtered search omits charities until category chip is cleared', (tester) async {
    final items = _Items()
      ..responses.addAll([
        _page(products: [_coat]),
        _page(),
        _page(),
      ]);
    await _open(tester, items, initialCategory: _women);

    await tester.enterText(find.byType(TextField), 'water aid');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Charities'), findsNothing);
    expect(find.text('WaterAid'), findsNothing);

    await tester.tap(find.byTooltip('Clear category'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Charities'), findsOneWidget);
    expect(find.text('WaterAid'), findsOneWidget);
  });

  testWidgets('SearchPage loads backend charities without duplicating Discover charities', (tester) async {
    final charitiesRepo = _Charities([
      Charity(
        id: 'QVAfoZuZfIlEoQOcsZ8F',
        name: 'Home Start',
        imageUrl: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      Charity(
        id: 'ca6tjKqCRurG0hB49Dcp',
        name: 'Water Aid',
        imageUrl: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ]);
    await _open(tester, _Items(), charityRepository: charitiesRepo);
    expect(charitiesRepo.fetchCalls, 1);

    await tester.enterText(find.byType(TextField), 'home start');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Home Start'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'water aid');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('WaterAid'), findsOneWidget);
    expect(find.text('Water Aid'), findsNothing);
  });
}
