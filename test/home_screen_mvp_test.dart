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

class _HomeRepositoryStub implements IHomeRepository {
  _HomeRepositoryStub(this.products);

  final List<Product> products;

  @override
  Future<Result<List<Product>>> fetchProducts() async {
    return Result.success(products);
  }
}

Future<void> _pumpHomeScreen(
  WidgetTester tester, {
  List<Product> products = const [],
  EdgeInsets mediaPadding = EdgeInsets.zero,
}) async {
  final navigator = NavigationProvider();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) => HomeViewModel(homeRepository: _HomeRepositoryStub(products)),
        ),
        ChangeNotifierProvider<ProductViewModel>(
          create: (_) => ProductViewModel(
            productRepository: ProductRepository(),
            navigator: navigator,
          ),
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
  testWidgets('HomeScreen hides the global search bar for the MVP', (
    tester,
  ) async {
    await _pumpHomeScreen(tester);

    expect(find.text('AI Search: Red Polka Dot Dress'), findsNothing);
    expect(find.byIcon(Icons.search), findsNothing);
  });

  testWidgets(
    'HomeScreen keeps the discover tile below the top safe area for the MVP',
    (tester) async {
      await _pumpHomeScreen(
        tester,
        mediaPadding: const EdgeInsets.only(top: 32),
      );

      final discoverTop = tester.getTopLeft(find.byType(DiscoverButton)).dy;

      expect(discoverTop, 48);
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
}
