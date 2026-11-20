import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/config/responsive_text_scaler.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/discover/discover_page.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/discover/discover_viewmodel.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/home_screen.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

class _HomeRepositoryStub implements IHomeRepository {
  @override
  Future<Result<ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
    String? categoryId,
  }) async {
    return Result.success(
      ProductPage(
        products: [
          Product(
            id: 'p1',
            name: 'Red Polka Dot Dress',
            description: 'Lovely dress',
            quality: 'Good',
            productImages: const [AppImages.product1],
            donation: 10,
            price: 12,
            securityFee: 1,
            likes: 2,
            number: 1,
            size: 'M',
            postageSizeId: 'small',
          ),
        ],
        limit: 20,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

class _CategoryRepositoryStub implements ICategoryRepository {
  @override
  Future<Result<List<Category>>> fetchCategories() async {
    return Result.success([
      for (final name in ['Women', 'Men', 'Children', 'Accessories'])
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

class _ProductRepositoryStub extends ProductRepository {
  _ProductRepositoryStub() : super(const UnexpectedApiService());

  @override
  Future<Result<List<Product>>> fetchLikedProducts() async {
    return Result.success(const []);
  }
}

Future<double> _pumpAndMeasureExploreHeight(
  WidgetTester tester,
  Size screenSize,
) async {
  tester.view.physicalSize = screenSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final navigator = NavigationProvider();
  final homeViewModel = HomeViewModel(homeRepository: _HomeRepositoryStub());
  addTearDown(homeViewModel.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        ChangeNotifierProvider.value(value: homeViewModel),
        ChangeNotifierProvider(
          create: (_) => CategoryViewModel(
            categoryRepository: _CategoryRepositoryStub(),
            navigator: navigator,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductViewModel(
            productRepository: _ProductRepositoryStub(),
            navigator: navigator,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DiscoverViewModel(discoverRepository: DiscoverRepository()),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        builder: ResponsiveTextScaler.builder,
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return tester.getSize(find.text('All')).height;
}

class _NonlinearTestTextScaler extends TextScaler {
  const _NonlinearTestTextScaler();

  @override
  double scale(double fontSize) {
    // Mimics Android 14 nonlinear 200% scaling where large headings scale less than small text.
    if (fontSize >= 30) return 38;
    return fontSize * 2.0;
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => 2.0;
}

void main() {
  test('scaleFactorForSize decreases on compact screens, stays 1.0 on phones, and increases on tablets', () {
    expect(
      ResponsiveTextScaler.scaleFactorForSize(const Size(320, 568)),
      closeTo(ResponsiveTextScaler.minScaleFactor, 1e-6),
    );
    expect(ResponsiveTextScaler.scaleFactorForSize(const Size(360, 800)), 1.0);
    expect(ResponsiveTextScaler.scaleFactorForSize(const Size(390, 844)), 1.0);
    expect(ResponsiveTextScaler.scaleFactorForSize(const Size(430, 932)), 1.0);
    expect(ResponsiveTextScaler.scaleFactorForSize(const Size(480, 900)), 1.0);

    final tabletPortrait = ResponsiveTextScaler.scaleFactorForSize(const Size(768, 1024));
    final tabletLandscape = ResponsiveTextScaler.scaleFactorForSize(const Size(1200, 800));
    expect(tabletPortrait, greaterThan(1.1));
    expect(tabletLandscape, closeTo(ResponsiveTextScaler.maxScaleFactor, 1e-6));
    expect(tabletLandscape, greaterThan(tabletPortrait));
  });

  test('textScalerFor combines OS accessibility scale and clamps at maxCombinedScale', () {
    final tabletScaler = ResponsiveTextScaler.textScalerFor(
      size: const Size(1200, 800),
      baseScaler: const TextScaler.linear(1.2),
    );
    expect(tabletScaler.scale(10), closeTo(10 * 1.2 * 1.35, 1e-4));

    final clampedScaler = ResponsiveTextScaler.textScalerFor(
      size: const Size(1200, 800),
      baseScaler: const TextScaler.linear(2.0),
    );
    expect(clampedScaler.scale(10), closeTo(10 * ResponsiveTextScaler.maxCombinedScale, 1e-4));

    final nonlinearPhoneScaler = ResponsiveTextScaler.textScalerFor(
      size: const Size(390, 844),
      baseScaler: const _NonlinearTestTextScaler(),
    );
    expect(nonlinearPhoneScaler.scale(12), closeTo(24, 1e-4));
    expect(nonlinearPhoneScaler.scale(30), closeTo(38, 1e-4));

    final nonlinearTabletScaler = ResponsiveTextScaler.textScalerFor(
      size: const Size(1200, 800),
      baseScaler: const _NonlinearTestTextScaler(),
    );
    expect(nonlinearTabletScaler.scale(30), closeTo(38 * 1.35, 1e-4));
  });

  testWidgets('HomeScreen text dynamically scales across compact phone, standard phone, and landscape tablet', (
    tester,
  ) async {
    final compactHeight = await _pumpAndMeasureExploreHeight(tester, const Size(320, 568));
    final phoneHeight = await _pumpAndMeasureExploreHeight(tester, const Size(390, 844));
    final tabletHeight = await _pumpAndMeasureExploreHeight(tester, const Size(1200, 800));

    expect(compactHeight, lessThan(phoneHeight));
    expect(tabletHeight, greaterThan(phoneHeight * 1.25));
  });

  testWidgets('DiscoverPage renders cleanly on a landscape tablet with scaled text', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigator = NavigationProvider();
    final homeViewModel = HomeViewModel(homeRepository: _HomeRepositoryStub());
    addTearDown(homeViewModel.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider.value(value: homeViewModel),
          ChangeNotifierProvider(
            create: (_) => CategoryViewModel(
              categoryRepository: _CategoryRepositoryStub(),
              navigator: navigator,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => ProductViewModel(
              productRepository: _ProductRepositoryStub(),
              navigator: navigator,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => DiscoverViewModel(discoverRepository: DiscoverRepository()),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.dark),
          builder: ResponsiveTextScaler.builder,
          home: const DiscoverPage(showBackButton: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Women'), findsOneWidget);
  });
}
