import 'dart:async';

import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_page.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_page.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/widgets/basket_list_item.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_card.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/widgets/order_card.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/unexpected_api_service.dart';

final _dogsTrust = Charity(
  id: 'dogs-trust',
  name: 'Dogs Trust',
  imageUrl: AppImages.mind,
  description:
      'Dogs Trust, the UK\'s largest dog welfare charity, cares for every dog.',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

final _otherCharity = Charity(
  id: 'other-charity',
  name: 'Other Charity',
  imageUrl: AppImages.wwf,
  description: 'Another charity.',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

final _dogsProduct1 = Product(
  id: 'dogs-p1',
  userId: 'seller-1',
  name: 'Example product 1',
  description: 'Unique description for Dogs Trust item 1',
  quality: 'Great',
  productImages: const [AppImages.product1],
  donation: 3.0,
  price: 3.0,
  securityFee: 0.30,
  likes: 3,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
  charityId: 'dogs-trust',
  charity: _dogsTrust,
);

final _dogsProduct2 = Product(
  id: 'dogs-p2',
  userId: 'seller-2',
  name: 'Example product 2',
  description: 'Unique description for Dogs Trust item 2',
  quality: 'Good',
  productImages: const [AppImages.product2],
  donation: 3.0,
  price: 3.0,
  securityFee: 0.30,
  likes: 3,
  number: 1,
  size: 'L',
  postageSizeId: 'small',
  charityId: 'dogs-trust',
  charity: _dogsTrust,
);

final _otherCharityProduct = Product(
  id: 'other-p1',
  userId: 'seller-3',
  name: 'Charity Y exclusive',
  description: 'Should never show on Dogs Trust profile',
  quality: 'Good',
  productImages: const [AppImages.product3],
  donation: 5.0,
  price: 5.0,
  securityFee: 0.50,
  likes: 1,
  number: 1,
  size: 'S',
  postageSizeId: 'small',
  charityId: 'other-charity',
  charity: _otherCharity,
);

class _FakeCharityProfileRepository implements ICharityProfileRepository {
  _FakeCharityProfileRepository({
    required this.charity,
    required this.returnedProducts,
  });

  final Charity charity;
  final List<Product> returnedProducts;

  @override
  Future<Result<Charity>> fetchCharity({
    String? charityId,
    String? charityName,
  }) async {
    return Result.success(charity);
  }

  @override
  Future<Result<CharityProfilePageData>> fetchProducts(
    Charity charity, {
    int limit = 20,
    String? cursor,
  }) async {
    return Result.success(
      CharityProfilePageData(
        charity: charity,
        products: returnedProducts,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

class _ProductRepositoryStub extends ProductRepository {
  _ProductRepositoryStub() : super(const UnexpectedApiService());

  @override
  Future<Result<List<Product>>> fetchLikedProducts() async =>
      Result.success(const []);

  @override
  Future<Result<Product>> fetchProduct(String productId) async {
    for (final item in [_dogsProduct1, _dogsProduct2, _otherCharityProduct]) {
      if (item.id == productId) return Result.success(item);
    }
    return Result.failure('Missing', statusCode: 404);
  }
}

class _CharityRepositoryStub implements ICharityRepository {
  @override
  Future<Result<List<Charity>>> fetchCharities() async =>
      Result.success([_dogsTrust, _otherCharity]);
}

class _CheckoutRepositoryStub implements ICheckoutRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DonationRepositoryStub implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapWithProviders({
  required NavigationProvider navigator,
  required ProductViewModel productViewModel,
  ICharityProfileRepository? charityProfileRepository,
  ICharityRepository? charityRepository,
  required Widget child,
  RouteFactory? onGenerateRoute,
}) {
  final checkoutViewModel = CheckoutViewModel(
    donationRepository: _DonationRepositoryStub(),
    checkoutRepository: _CheckoutRepositoryStub(),
    navigator: navigator,
    currentUserIdProvider: () => 'buyer-1',
  );
  return MultiProvider(
    providers: [
      Provider<NavigationProvider>.value(value: navigator),
      ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
      ChangeNotifierProvider<CheckoutViewModel>.value(value: checkoutViewModel),
      if (charityProfileRepository != null)
        Provider<ICharityProfileRepository>.value(
          value: charityProfileRepository,
        ),
      if (charityRepository != null)
        ChangeNotifierProvider<CharityViewModel>(
          create: (_) => CharityViewModel(
            charityRepository: charityRepository,
            navigator: navigator,
          ),
        ),
    ],
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      navigatorKey: navigator.navigatorKey,
      onGenerateRoute: onGenerateRoute ?? AppRoutes.generateRoute,
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'renders Dogs Trust layout, isolates charity listings, navigates to ProductPage and back',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navigator = NavigationProvider();
      final productViewModel = ProductViewModel(
        productRepository: _ProductRepositoryStub(),
        navigator: navigator,
        currentUserIdProvider: () => 'buyer-1',
      )..setProduct(_otherCharityProduct);

      final repo = _FakeCharityProfileRepository(
        charity: _dogsTrust,
        returnedProducts: [_dogsProduct1, _otherCharityProduct, _dogsProduct2],
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          navigator: navigator,
          productViewModel: productViewModel,
          charityProfileRepository: repo,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CharityProfilePage(
                        args: CharityProfileArgs(charity: _dogsTrust),
                        repository: repo,
                      ),
                    ),
                  ),
                  child: const Text('Open Dogs Trust'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dogs Trust'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.charityProfileTitle), findsOneWidget);
      expect(find.text('Dogs Trust'), findsOneWidget);
      expect(find.text(AppStrings.charityProfileLocation), findsOneWidget);
      expect(find.text(_dogsTrust.description!), findsOneWidget);

      // Verify description renders above product listings.
      final descBottom = tester.getBottomLeft(find.text(_dogsTrust.description!)).dy;
      final firstCardTop = tester.getTopLeft(find.text('Example product 1')).dy;
      expect(descBottom, lessThan(firstCardTop));

      // Verify Charity X items show and Charity Y item is strictly excluded.
      expect(find.text('Example product 1'), findsOneWidget);
      expect(find.text('Example product 2'), findsOneWidget);
      expect(find.text('Charity Y exclusive'), findsNothing);

      // Selecting a product opens ProductPage; pressing back returns to CharityProfilePage.
      await tester.tap(find.text('Example product 1'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductPage), findsOneWidget);
      expect(find.text(_dogsProduct1.description), findsOneWidget);

      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();
      expect(find.byType(CharityProfilePage), findsOneWidget);
      expect(find.text('Dogs Trust'), findsOneWidget);

      // Workable back button on CharityProfilePage returns to previous route.
      await tester.tap(find.byKey(const ValueKey('charity-profile-back-button')));
      await tester.pumpAndSettle();
      expect(find.text('Open Dogs Trust'), findsOneWidget);
    },
  );

  testWidgets(
    'preserves earlier ProductPage route across Product A -> View Charity Profile -> Product B -> Back -> Back',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navigator = NavigationProvider();
      final productViewModel = ProductViewModel(
        productRepository: _ProductRepositoryStub(),
        navigator: navigator,
        currentUserIdProvider: () => 'buyer-1',
      )..setProduct(_otherCharityProduct);

      final repo = _FakeCharityProfileRepository(
        charity: _dogsTrust,
        returnedProducts: [_dogsProduct1, _dogsProduct2],
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          navigator: navigator,
          productViewModel: productViewModel,
          charityProfileRepository: repo,
          child: const ProductPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Ancestor route initially displays Product A (_otherCharityProduct).
      expect(find.text(_otherCharityProduct.description), findsOneWidget);

      // Navigate into Dogs Trust charity profile via View Charity Profile route.
      unawaited(navigator.openCharityProfile(_dogsTrust));
      await tester.pumpAndSettle();
      expect(find.byType(CharityProfilePage), findsOneWidget);

      // Open Product B (_dogsProduct2) from Dogs Trust profile.
      await tester.tap(find.text('Example product 2'));
      await tester.pumpAndSettle();
      expect(find.text(_dogsProduct2.description), findsOneWidget);

      // Pop from Product B back to Dogs Trust CharityProfilePage.
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();
      expect(find.byType(CharityProfilePage), findsOneWidget);

      // Pop from CharityProfilePage back to original Product A route.
      await tester.tap(find.byKey(const ValueKey('charity-profile-back-button')));
      await tester.pumpAndSettle();
      expect(find.byType(ProductPage), findsOneWidget);
      expect(find.text(_otherCharityProduct.description), findsOneWidget);
    },
  );

  testWidgets(
    'requires confirmation popup before reporting or blocking a charity',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final reports = <Map<String, String?>>[];
      final blocks = <String>[];
      final navigator = NavigationProvider();
      final productViewModel = ProductViewModel(
        productRepository: _ProductRepositoryStub(),
        navigator: navigator,
        currentUserIdProvider: () => 'buyer-1',
      );
      final repo = _FakeCharityProfileRepository(
        charity: _dogsTrust,
        returnedProducts: [_dogsProduct1],
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          navigator: navigator,
          productViewModel: productViewModel,
          charityProfileRepository: repo,
          child: CharityProfilePage(
            args: CharityProfileArgs(charity: _dogsTrust),
            repository: repo,
            onReportCharity: (charityId, {required reason, message}) async {
              reports.add({
                'charityId': charityId,
                'reason': reason,
                'message': message,
              });
              return Result.success(null);
            },
            onBlockCharity: (charityId) async {
              blocks.add(charityId);
              return Result.success(null);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Report charity: cancelling confirmation popup prevents opening report sheet.
      await tester.tap(find.byKey(const ValueKey('charity-profile-safety-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.reportCharityMenuLabel));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.reportCharityConfirmTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.productPageCancel));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.productPageReportSubmit), findsNothing);
      expect(reports, isEmpty);

      // Confirm report popup -> opens report sheet -> submit report.
      await tester.tap(find.byKey(const ValueKey('charity-profile-safety-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.reportCharityMenuLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.reportCharityConfirmAction));
      await tester.pumpAndSettle();
      expect(find.text('Misleading information'), findsOneWidget);
      await tester.tap(find.text('Misleading information'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.productPageReportSubmit));
      await tester.pumpAndSettle();
      expect(reports, [
        {
          'charityId': 'dogs-trust',
          'reason': 'misleading_information',
          'message': '',
        },
      ]);

      // 2. Block charity: cancelling confirmation popup leaves listings visible.
      await tester.tap(find.byKey(const ValueKey('charity-profile-safety-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.blockCharityMenuLabel));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.blockCharityConfirmTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.productPageCancel));
      await tester.pumpAndSettle();
      expect(blocks, isEmpty);
      expect(find.text('Example product 1'), findsOneWidget);

      // Confirm block popup -> calls block handler and hides listings.
      await tester.tap(find.byKey(const ValueKey('charity-profile-safety-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.blockCharityMenuLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.blockCharityConfirmAction));
      await tester.pumpAndSettle();
      expect(blocks, ['dogs-trust']);
      expect(find.text('Example product 1'), findsNothing);
      expect(find.text(AppStrings.charityProfileBlockedMessage), findsOneWidget);
    },
  );

  testWidgets(
    'all charity logo touchpoints open CharityProfilePage except CharityPage selectionMode',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final openedRoutes = <CharityProfileArgs>[];

      Route<dynamic> captureRoute(RouteSettings settings) {
        if (settings.name == AppRoutes.charityProfile) {
          openedRoutes.add(CharityProfileArgs.fromRouteArgument(settings.arguments)!);
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Charity Destination')),
          );
        }
        return AppRoutes.generateRoute(settings);
      }

      ProductViewModel makeVm(NavigationProvider nav) => ProductViewModel(
            productRepository: _ProductRepositoryStub(),
            navigator: nav,
            currentUserIdProvider: () => 'buyer-1',
          );

      // A. ProductCard badge
      final navA = NavigationProvider();
      await tester.pumpWidget(
        _wrapWithProviders(
          navigator: navA,
          productViewModel: makeVm(navA),
          onGenerateRoute: captureRoute,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: ProductCard(product: _dogsProduct1),
              ),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(ValueKey('product-card-charity-logo-${_dogsProduct1.id}')),
      );
      await tester.pumpAndSettle();
      expect(openedRoutes.last.charityId, 'dogs-trust');

      // B. DiscoverCharityCard logo badge and cover image
      final navB = NavigationProvider();
      await tester.pumpWidget(
        _wrapWithProviders(
          navigator: navB,
          productViewModel: makeVm(navB),
          onGenerateRoute: captureRoute,
          child: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 240,
                child: DiscoverCharityCard(
                  title: 'Dogs Trust',
                  description: 'Desc',
                  imagePath: AppImages.product1,
                  logoPath: AppImages.mind,
                  likes: 4,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage(AppImages.product1),
          tester.element(find.byType(DiscoverCharityCard)),
        ),
      );
      await tester.pumpAndSettle();

      // Tapping the like button toggles like state without opening the profile.
      final countBeforeLikeTap = openedRoutes.length;
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('discover-charity-like-Dogs Trust')),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(openedRoutes.length, countBeforeLikeTap);

      // Tapping the cover image opens CharityProfilePage.
      await tester.tap(
        find.byKey(const ValueKey('discover-charity-image-Dogs Trust')),
      );
      await tester.pumpAndSettle();
      expect(openedRoutes.length, countBeforeLikeTap + 1);
      expect(openedRoutes.last.charityName, 'Dogs Trust');
      expect(openedRoutes.last.charityImageUrl, AppImages.mind);
      navB.goBack();
      await tester.pumpAndSettle();

      // Tapping the logo badge also opens CharityProfilePage.
      await tester.tap(
        find.byKey(const ValueKey('discover-charity-logo-Dogs Trust')),
      );
      await tester.pumpAndSettle();
      expect(openedRoutes.length, countBeforeLikeTap + 2);
      expect(openedRoutes.last.charityName, 'Dogs Trust');

      // C. OrderCard logo badge
      const order = OrderSummary(
        id: 'order-1',
        productId: 'dogs-p1',
        productName: 'Shirt',
        imageUrl: '',
        size: 'M',
        charityId: 'dogs-trust',
        charityLogoUrl: AppImages.mind,
        itemPriceMinor: 300,
        totalAmountMinor: 330,
        currency: 'GBP',
        deliveryState: 'pending',
        deliveryLabel: '',
      );
      final navC = NavigationProvider();
      await tester.pumpWidget(
        _wrapWithProviders(
          navigator: navC,
          productViewModel: makeVm(navC),
          onGenerateRoute: captureRoute,
          child: const Scaffold(body: OrderCard(order: order)),
        ),
      );
      expect(
        find.bySemanticsLabel(AppStrings.charityProfileViewButton),
        findsOneWidget,
      );
      final countBeforeOrderTap = openedRoutes.length;
      await tester.tap(find.byKey(const ValueKey('order-charity-logo-order-1')));
      await tester.pumpAndSettle();
      expect(openedRoutes.length, countBeforeOrderTap + 1);
      expect(openedRoutes.last.charityId, 'dogs-trust');

      // D. BasketListItem charity logo badge
      final navD = NavigationProvider();
      final basketProduct = Product(
        id: _dogsProduct1.id,
        userId: _dogsProduct1.userId,
        name: _dogsProduct1.name,
        description: _dogsProduct1.description,
        quality: _dogsProduct1.quality,
        productImages: const [],
        donation: _dogsProduct1.donation,
        price: _dogsProduct1.price,
        securityFee: _dogsProduct1.securityFee,
        likes: _dogsProduct1.likes,
        number: _dogsProduct1.number,
        size: _dogsProduct1.size,
        postageSizeId: _dogsProduct1.postageSizeId,
        charityId: _dogsProduct1.charityId,
        charity: _dogsProduct1.charity,
      );
      await tester.pumpWidget(
        _wrapWithProviders(
          navigator: navD,
          productViewModel: makeVm(navD),
          onGenerateRoute: captureRoute,
          child: Scaffold(body: BasketListItem(product: basketProduct)),
        ),
      );
      final countBeforeBasketTap = openedRoutes.length;
      await tester.tap(
        find.byKey(ValueKey('basket-charity-logo-${_dogsProduct1.id}')),
      );
      await tester.pumpAndSettle();
      expect(openedRoutes.length, countBeforeBasketTap + 1);
      expect(openedRoutes.last.charityId, 'dogs-trust');

      // E. CharityPage browse mode (selectionMode: false) opens CharityProfilePage
      final routeCountBeforeBrowse = openedRoutes.length;
      final navE = NavigationProvider();
      await tester.pumpWidget(
        _wrapWithProviders(
          navigator: navE,
          productViewModel: makeVm(navE),
          charityRepository: _CharityRepositoryStub(),
          onGenerateRoute: captureRoute,
          child: const CharityPage(selectionMode: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dogs Trust'));
      await tester.pumpAndSettle();
      expect(openedRoutes.length, routeCountBeforeBrowse + 1);
      expect(openedRoutes.last.charityId, 'dogs-trust');

      // F. CharityPage listing selection mode (selectionMode: true) returns selection cleanly
      final navKey2 = NavigationProvider();
      Charity? selectedFromListing;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<NavigationProvider>.value(value: navKey2),
            ChangeNotifierProvider<ProductViewModel>.value(value: makeVm(navKey2)),
            ChangeNotifierProvider<CharityViewModel>(
              create: (_) => CharityViewModel(
                charityRepository: _CharityRepositoryStub(),
                navigator: navKey2,
              ),
            ),
          ],
          child: MaterialApp(
            navigatorKey: navKey2.navigatorKey,
            onGenerateRoute: captureRoute,
            home: Scaffold(
              body: TextButton(
                onPressed: () async {
                  final picked = await navKey2.navigatorKey.currentState!
                      .push<Charity>(
                    MaterialPageRoute(
                      builder: (_) => const CharityPage(selectionMode: true),
                    ),
                  );
                  selectedFromListing = picked;
                },
                child: const Text('Pick Charity'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pick Charity'));
      await tester.pumpAndSettle();
      final countBeforeSelectionTap = openedRoutes.length;
      await tester.tap(find.text('Dogs Trust'));
      await tester.pumpAndSettle();
      expect(openedRoutes.length, countBeforeSelectionTap);
      expect(selectedFromListing?.id, 'dogs-trust');
    },
  );

  testWidgets(
    'empty charity listings state shows branded List an item button that navigates to Donations with charity preselected',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navigator = NavigationProvider();
      final productViewModel = ProductViewModel(
        productRepository: _ProductRepositoryStub(),
        navigator: navigator,
        currentUserIdProvider: () => 'buyer-1',
      );
      final emptyRepo = _FakeCharityProfileRepository(
        charity: _dogsTrust,
        returnedProducts: const [],
      );
      Charity? capturedInitialCharity;

      await tester.pumpWidget(
        _wrapWithProviders(
          navigator: navigator,
          productViewModel: productViewModel,
          charityProfileRepository: emptyRepo,
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.donations) {
              capturedInitialCharity = settings.arguments as Charity?;
              return MaterialPageRoute<bool>(
                settings: settings,
                builder: (_) => const Scaffold(
                  body: Text('Donation Listing Destination'),
                ),
              );
            }
            return AppRoutes.generateRoute(settings);
          },
          child: CharityProfilePage(
            args: CharityProfileArgs(charity: _dogsTrust),
            repository: emptyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.charityProfileEmptyListings), findsOneWidget);
      final listButton = find.byKey(
        const ValueKey('charity-profile-list-item-button'),
      );
      expect(listButton, findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, AppStrings.charityProfileListAnItem),
        findsOneWidget,
      );

      await tester.tap(listButton);
      await tester.pumpAndSettle();

      expect(find.text('Donation Listing Destination'), findsOneWidget);
      expect(capturedInitialCharity?.id, 'dogs-trust');
      expect(capturedInitialCharity?.name, 'Dogs Trust');
    },
  );

  testWidgets(
    'keeps Load more accessible when first page listings are filtered out and refreshes when embedded charity changes',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navigator = NavigationProvider();
      final productViewModel = ProductViewModel(
        productRepository: _ProductRepositoryStub(),
        navigator: navigator,
        currentUserIdProvider: () => 'buyer-1',
      );

      final paginatedRepo = _PaginatedCharityProfileRepository(
        onFetchCharity: ({charityId, charityName}) async => Result.success(
          charityId == 'other-charity' ? _otherCharity : _dogsTrust,
        ),
        onFetchProducts: (charity, {limit = 20, cursor}) async {
          if (charity.id == 'other-charity') {
            return Result.success(
              CharityProfilePageData(
                charity: charity,
                products: [_otherCharityProduct],
                nextCursor: null,
                hasMore: false,
              ),
            );
          }
          if (cursor == null) {
            // Page 1 returns only an item belonging to another charity, which
            // CharityProfileViewModel filters out, leaving products empty while hasMore is true.
            return Result.success(
              CharityProfilePageData(
                charity: charity,
                products: [_otherCharityProduct],
                nextCursor: 'page-2',
                hasMore: true,
              ),
            );
          }
          return Result.success(
            CharityProfilePageData(
              charity: charity,
              products: [_dogsProduct1],
              nextCursor: null,
              hasMore: false,
            ),
          );
        },
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          navigator: navigator,
          productViewModel: productViewModel,
          charityProfileRepository: paginatedRepo,
          child: CharityProfilePage(
            args: CharityProfileArgs(charity: _dogsTrust),
            repository: paginatedRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Even though filtered products are empty on page 1, Load more is visible.
      expect(find.text(AppStrings.profileListingsLoadMore), findsOneWidget);
      await tester.tap(find.text(AppStrings.profileListingsLoadMore));
      await tester.pumpAndSettle();
      expect(find.text('Example product 1'), findsOneWidget);

      // Replacing the embedded Charity object (without separate charityId/charityName) refreshes the page.
      await tester.pumpWidget(
        _wrapWithProviders(
          navigator: navigator,
          productViewModel: productViewModel,
          charityProfileRepository: paginatedRepo,
          child: CharityProfilePage(
            args: CharityProfileArgs(charity: _otherCharity),
            repository: paginatedRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Other Charity'), findsOneWidget);
      expect(find.text('Charity Y exclusive'), findsOneWidget);
    },
  );
}

class _PaginatedCharityProfileRepository implements ICharityProfileRepository {
  _PaginatedCharityProfileRepository({
    required this.onFetchCharity,
    required this.onFetchProducts,
  });

  final Future<Result<Charity>> Function({
    String? charityId,
    String? charityName,
  }) onFetchCharity;
  final Future<Result<CharityProfilePageData>> Function(
    Charity charity, {
    int limit,
    String? cursor,
  }) onFetchProducts;

  @override
  Future<Result<Charity>> fetchCharity({
    String? charityId,
    String? charityName,
  }) => onFetchCharity(charityId: charityId, charityName: charityName);

  @override
  Future<Result<CharityProfilePageData>> fetchProducts(
    Charity charity, {
    int limit = 20,
    String? cursor,
  }) => onFetchProducts(charity, limit: limit, cursor: cursor);
}
