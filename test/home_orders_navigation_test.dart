import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/discover/discover_page.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/discover/discover_viewmodel.dart';
import 'package:cherry_mvp/features/donation/donation_page.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:cherry_mvp/features/home/home_page.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/discover_button.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/orders_repository.dart';
import 'package:cherry_mvp/features/orders/orders_view_model.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/profile/profile_page.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class _HomeRepositoryStub implements IHomeRepository {
  @override
  Future<Result<ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
    String? categoryId,
  }) async {
    return Result.success(
      const ProductPage(
        products: <Product>[],
        limit: 20,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

// Navigation only fetches orders; Fake throws for unexpected repository calls.
class _OrdersRepositoryStub extends Fake implements IOrdersRepository {
  @override
  Future<Result<dynamic>> confirmOrderReceived(String orderId) async {
    return Result.success(null);
  }

  @override
  Future<Result<List<OrderSummary>>> fetchOrders() async {
    return Result.success(const []);
  }

  @override
  Future<Result<dynamic>> submitOrderDispute(
    String orderId, {
    required String reason,
    String? message,
  }) async {
    return Result.success(null);
  }
}

class _ProfileListingsRepositoryStub implements IProfileListingsRepository {
  List<SellerListing> listings = [];
  int fetchCount = 0;

  @override
  Future<Result<ProfileListingsPage>> fetchListings({
    int limit = 20,
    String? cursor,
  }) async {
    fetchCount++;
    return Result.success(
      ProfileListingsPage(
        listings: List.of(listings),
        limit: 20,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

class _CategoryRepositoryStub implements ICategoryRepository {
  @override
  Future<Result<List<Category>>> fetchCategories() async => Result.success([]);
}

class _CharityRepositoryStub implements ICharityRepository {
  @override
  Future<Result<List<Charity>>> fetchCharities() async => Result.success([]);
}

class _DonationRepositoryStub extends Fake implements IDonationRepository {}

class _ProductRepositoryStub extends ProductRepository {
  _ProductRepositoryStub() : super(_ApiServiceMock());

  @override
  Future<Result<List<Product>>> fetchLikedProducts() async => Result.success(const []);
}

class _NavigationObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  final List<Route<dynamic>> poppedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
  }
}

class _ApiServiceMock extends Mock implements ApiService {}

class _FirebaseAuthMock extends Mock implements FirebaseAuth {}

class _FirebaseFirestoreMock extends Mock implements FirebaseFirestore {}

class _LoginRepositoryMock extends Mock implements LoginRepository {}

Future<NavigationProvider> _pumpHomePage(
  WidgetTester tester, {
  _ProfileListingsRepositoryStub? listingsRepository,
  NavigatorObserver? observer,
}) async {
  final navigator = NavigationProvider();
  final firebaseAuth = _FirebaseAuthMock();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        Provider<ProductRepository>(create: (_) => _ProductRepositoryStub()),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(homeRepository: _HomeRepositoryStub()),
        ),
        ChangeNotifierProvider(
          create: (context) => ProductViewModel(
            productRepository: context.read<ProductRepository>(),
            navigator: navigator,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DiscoverViewModel(discoverRepository: DiscoverRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => OrdersViewModel(repository: _OrdersRepositoryStub()),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileListingsViewModel(
            repository: listingsRepository ?? _ProfileListingsRepositoryStub(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DonationViewModel(
            donationRepository: _DonationRepositoryStub(),
            navigator: navigator,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryViewModel(
            categoryRepository: _CategoryRepositoryStub(),
            navigator: navigator,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CharityViewModel(
            charityRepository: _CharityRepositoryStub(),
            navigator: navigator,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            loginRepository: _LoginRepositoryMock(),
            navigator: navigator,
            firebaseAuth: firebaseAuth,
            firestore: _FirebaseFirestoreMock(),
            apiService: _ApiServiceMock(),
          ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigator.navigatorKey,
        navigatorObservers: [?observer],
        onGenerateRoute: AppRoutes.generateRoute,
        home: const HomePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return navigator;
}

Future<void> _openOrders(WidgetTester tester) async {
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Orders'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('footer lists Home, Discover, Give, Profile in that order', (tester) async {
    await _pumpHomePage(tester);

    final labels = ['Home', 'Discover', 'Give', 'Profile'];
    final positions = [for (final label in labels) tester.getTopLeft(find.text(label)).dx];
    expect(positions, orderedEquals([...positions]..sort()));
    expect(find.byIcon(Icons.public_rounded), findsOneWidget);
  });

  testWidgets('Discover footer tab shows the Discover page and returns to Home', (tester) async {
    await _pumpHomePage(tester);
    expect(find.byType(DiscoverPage), findsNothing);

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex, 1);
    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex, 0);
  });

  testWidgets('Explore Charities banner on Home switches to the Discover tab', (tester) async {
    final navigator = await _pumpHomePage(tester);

    await tester.tap(find.byType(DiscoverButton));
    await tester.pumpAndSettle();

    expect(tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex, 1);
    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(navigator.navigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets('tapping Discover from Liked Items pops back to HomePage with Discover selected', (tester) async {
    final navigator = await _pumpHomePage(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liked'));
    await tester.pumpAndSettle();
    expect(navigator.navigatorKey.currentState!.canPop(), isTrue);

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(navigator.navigatorKey.currentState!.canPop(), isFalse);
    expect(tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex, 1);
    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('tapping Discover from Liked Items on standalone ProfilePage navigates to Discover route', (
    tester,
  ) async {
    final navigator = await _pumpHomePage(tester);
    navigator.navigateTo(AppRoutes.myListings);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Liked'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('swiping between Home and Discover keeps the footer in step', (tester) async {
    await _pumpHomePage(tester);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex, 1);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex, 0);
  });

  testWidgets('successful Give result selects existing Profile and shows the new listing', (tester) async {
    final repository = _ProfileListingsRepositoryStub();
    final observer = _NavigationObserver();
    final navigator = await _pumpHomePage(tester, listingsRepository: repository, observer: observer);
    final originalHome = tester.state(find.byType(HomePage));

    await tester.tap(find.text('Give'));
    await tester.pumpAndSettle();
    expect(find.byType(DonationPage), findsOneWidget);

    repository.listings = [
      const SellerListing(id: 'new-listing', name: 'New listing', imageUrls: [], price: 12.5),
    ];
    // The submission flow returns true only after posting successfully.
    navigator.goBack(true);
    await tester.pumpAndSettle();

    expect(tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex, 3);
    expect(find.byKey(const ValueKey('new-listing')), findsOneWidget);
    expect(tester.state(find.byType(HomePage)), same(originalHome));
    expect(find.byType(DonationPage), findsNothing);
    expect(observer.pushedRoutes, hasLength(2));
    expect(observer.poppedRoutes, hasLength(1));
    expect(navigator.navigatorKey.currentState!.canPop(), isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DonationPage), findsNothing);
  });

  testWidgets('successful Give result refreshes listings when Profile is already selected', (tester) async {
    final repository = _ProfileListingsRepositoryStub()
      ..listings = [
        const SellerListing(id: 'old-listing', name: 'Old listing', imageUrls: [], price: 8),
      ];
    final navigator = await _pumpHomePage(tester, listingsRepository: repository);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    final previousFetchCount = repository.fetchCount;
    final originalProfile = tester.state(find.byType(ProfilePage));

    await tester.tap(find.text('Give'));
    await tester.pumpAndSettle();
    repository.listings = [
      const SellerListing(id: 'new-listing', name: 'New listing', imageUrls: [], price: 12.5),
      ...repository.listings,
    ];
    navigator.goBack(true);
    await tester.pumpAndSettle();

    expect(repository.fetchCount, previousFetchCount + 1);
    expect(tester.state(find.byType(ProfilePage)), same(originalProfile));
    expect(find.byKey(const ValueKey('new-listing')), findsOneWidget);
    expect(find.byKey(const ValueKey('old-listing')), findsOneWidget);
    expect(navigator.navigatorKey.currentState!.canPop(), isFalse);
  });

  for (final result in [null, false]) {
    testWidgets('unsuccessful Give result $result keeps Home selected', (tester) async {
      final repository = _ProfileListingsRepositoryStub();
      final navigator = await _pumpHomePage(tester, listingsRepository: repository);
      final previousFetchCount = repository.fetchCount;

      await tester.tap(find.text('Give'));
      await tester.pumpAndSettle();
      navigator.goBack(result);
      await tester.pumpAndSettle();

      expect(tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex, 0);
      expect(repository.fetchCount, previousFetchCount);
      expect(find.byType(DonationPage), findsNothing);
      expect(navigator.navigatorKey.currentState!.canPop(), isFalse);
    });
  }

  testWidgets('Profile empty-state listing action refreshes after a successful named upload', (tester) async {
    final repository = _ProfileListingsRepositoryStub();
    final navigator = await _pumpHomePage(tester, listingsRepository: repository);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    final originalProfile = tester.state(find.byType(ProfilePage));
    final previousFetchCount = repository.fetchCount;

    await tester.ensureVisible(find.text('List an item'));
    await tester.tap(find.text('List an item'));
    await tester.pumpAndSettle();
    expect(find.byType(DonationPage), findsOneWidget);

    repository.listings = [
      const SellerListing(id: 'new-listing', name: 'New listing', imageUrls: [], price: 12.5),
    ];
    navigator.goBack(true);
    await tester.pumpAndSettle();

    expect(repository.fetchCount, previousFetchCount + 1);
    expect(tester.state(find.byType(ProfilePage)), same(originalProfile));
    expect(find.byKey(const ValueKey('new-listing')), findsOneWidget);
    expect(find.text('You have not listed anything yet.'), findsNothing);
    expect(navigator.navigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets('My Orders retains one bottom bar with Profile selected', (
    tester,
  ) async {
    await _pumpHomePage(tester);
    await _openOrders(tester);

    expect(find.text('My Orders'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(
      tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
      3,
    );
  });

  testWidgets('visual and system back return My Orders to Profile', (
    tester,
  ) async {
    await _pumpHomePage(tester);
    await _openOrders(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsNothing);
    expect(find.text('Profile'), findsWidgets);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('My Orders'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsNothing);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('leaving or re-tapping Profile resets My Orders', (tester) async {
    await _pumpHomePage(tester);
    await _openOrders(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('My Orders'), findsNothing);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsNothing);
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets('Profile remains mounted while My Orders is visible', (
    tester,
  ) async {
    await _pumpHomePage(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    final profileFinder = find.byType(ProfilePage, skipOffstage: false);
    final originalState = tester.state(profileFinder);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsOneWidget);
    expect(tester.state(profileFinder), same(originalState));
  });

  testWidgets('swiping away from Profile resets My Orders', (tester) async {
    await _pumpHomePage(tester);
    await _openOrders(tester);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsNothing);
    expect(find.text('Orders'), findsOneWidget);
  });
}
