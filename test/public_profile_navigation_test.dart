import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/seller_information.dart';
import 'package:cherry_mvp/features/profile/widgets/seller_listing_card.dart';
import 'package:cherry_mvp/features/profile/public_user_profile.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

class _RecordingNavigationProvider extends NavigationProvider {
  final calls = <({String route, Object? arguments})>[];

  @override
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) async {
    calls.add((route: routeName, arguments: arguments));
  }
}

class _CheckoutRepositoryStub implements ICheckoutRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DonationRepositoryStub implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PublicProfileRepository implements IPublicUserProfileRepository {
  _PublicProfileRepository({this.products = const []});

  final List<Product> products;
  final calls = <({String userId, int limit, String? cursor})>[];
  bool fail = false;

  @override
  Future<Result<PublicUserProfilePage>> fetchProfile(
    String userId, {
    int limit = 20,
    String? cursor,
  }) async {
    calls.add((userId: userId, limit: limit, cursor: cursor));
    if (fail) return Result.failure('Unavailable');
    return Result.success(
      PublicUserProfilePage(
        user: PublicUser(id: userId, username: 'Seller $userId'),
        products: products,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

Product _product({
  String id = 'first-listing',
  String name = 'First jumper',
  String? userId = 'seller-1',
}) => Product(
  id: id,
  userId: userId,
  name: name,
  description: '$name description',
  quality: 'Good',
  productImages: const [AppImages.product1],
  donation: 20,
  price: 20,
  securityFee: 2,
  likes: 0,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
);

Future<({NavigationProvider navigator, ProductViewModel products})> _pumpApp(
  WidgetTester tester, {
  required _PublicProfileRepository repository,
  Widget home = const Scaffold(body: Text('Home')),
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = NavigationProvider();
  final products = ProductViewModel(
    productRepository: ProductRepository(const UnexpectedApiService()),
    navigator: navigator,
  );
  final checkout = CheckoutViewModel(
    donationRepository: _DonationRepositoryStub(),
    checkoutRepository: _CheckoutRepositoryStub(),
    navigator: navigator,
  );
  addTearDown(products.dispose);
  addTearDown(checkout.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        Provider<IPublicUserProfileRepository>.value(value: repository),
        ChangeNotifierProvider<ProductViewModel>.value(value: products),
        ChangeNotifierProvider<CheckoutViewModel>.value(value: checkout),
      ],
      child: MaterialApp(
        navigatorKey: navigator.navigatorKey,
        onGenerateRoute: AppRoutes.generateRoute,
        home: home,
      ),
    ),
  );
  return (navigator: navigator, products: products);
}

void main() {
  test('shared profile navigation trims the user ID', () async {
    final navigator = _RecordingNavigationProvider();
    await navigator.openPublicUserProfile('  seller-1  ');
    expect(navigator.calls, [
      (route: AppRoutes.publicUserProfile, arguments: 'seller-1'),
    ]);
  });

  test('shared profile navigation ignores missing and malformed IDs', () async {
    final navigator = _RecordingNavigationProvider();
    for (final userId in [
      null,
      '',
      '  ',
      'seller/other',
      '.',
      '..',
      'deleted_user',
      r'seller\other',
      'bad\nidentity',
    ]) {
      await navigator.openPublicUserProfile(userId);
    }
    expect(navigator.calls, isEmpty);
  });

  test('listing navigation passes its own product as a route argument', () {
    final navigator = _RecordingNavigationProvider();
    final products = ProductViewModel(
      productRepository: ProductRepository(const UnexpectedApiService()),
      navigator: navigator,
    );
    addTearDown(products.dispose);
    final product = _product();
    products.goToProductPage(product);
    expect(navigator.calls.single.route, AppRoutes.product);
    expect(navigator.calls.single.arguments, same(product));
  });

  for (final useAvatar in [false, true]) {
    testWidgets(
      'seller ${useAvatar ? 'avatar' : 'name'} opens that seller’s profile',
      (tester) async {
        final repository = _PublicProfileRepository();
        final app = await _pumpApp(tester, repository: repository);
        app.products.goToProductPage(_product());
        await tester.pumpAndSettle();

        final target = useAvatar
            ? find.descendant(
                of: find.byType(SellerInformation),
                matching: find.byType(CircleAvatar),
              )
            : find.text('Seller seller-1');
        await tester.tap(target);
        await tester.pumpAndSettle();

        expect(
          tester.widget<PublicUserProfile>(find.byType(PublicUserProfile)).userId,
          'seller-1',
        );
        expect(repository.calls.last.userId, 'seller-1');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('invalid product seller IDs disable the identity link', (tester) async {
    for (final userId in [null, '', '  ', 'seller/other']) {
      final repository = _PublicProfileRepository();
      final app = await _pumpApp(tester, repository: repository);
      app.products.goToProductPage(_product(userId: userId));
      await tester.pumpAndSettle();

      expect(
        tester.widget<SellerInformation>(find.byType(SellerInformation)).onViewProfile,
        isNull,
      );
      await tester.tap(find.text('User'));
      await tester.pumpAndSettle();
      expect(find.byType(PublicUserProfile), findsNothing);
      expect(repository.calls, isEmpty);
    }
  });

  testWidgets('malformed public-profile routes do not fetch a user', (tester) async {
    final repository = _PublicProfileRepository();
    final app = await _pumpApp(tester, repository: repository);
    for (final argument in [
      null,
      '',
      'seller/other',
      42,
      {'userId': 'seller-1'},
    ]) {
      app.navigator.navigateTo(AppRoutes.publicUserProfile, arguments: argument);
      await tester.pumpAndSettle();
      expect(find.text('This profile is unavailable.'), findsOneWidget);
      expect(find.byType(PublicUserProfile), findsNothing);
      app.navigator.goBack();
      await tester.pumpAndSettle();
    }
    expect(repository.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed public seller lookup keeps a usable generic profile link', (tester) async {
    final repository = _PublicProfileRepository()..fail = true;
    final app = await _pumpApp(tester, repository: repository);
    app.products.goToProductPage(_product());
    await tester.pumpAndSettle();

    expect(find.text('User'), findsOneWidget);
    await tester.tap(find.text('User'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicUserProfile), findsOneWidget);
    expect(repository.calls.last.userId, 'seller-1');
  });

  testWidgets('nested listing navigation preserves the original detail and seller', (tester) async {
    final secondProduct = _product(id: 'second-listing', name: 'Second coat');
    final repository = _PublicProfileRepository(products: [secondProduct]);
    final app = await _pumpApp(tester, repository: repository);
    app.products.goToProductPage(_product());
    await tester.pumpAndSettle();
    expect(find.text('First jumper'), findsOneWidget);

    await tester.tap(find.text('Seller seller-1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SellerListingCard));
    await tester.pumpAndSettle();
    expect(find.text('Second coat'), findsOneWidget);

    app.navigator.goBack();
    await tester.pumpAndSettle();
    expect(find.byType(PublicUserProfile), findsOneWidget);
    app.navigator.goBack();
    await tester.pumpAndSettle();

    expect(find.text('First jumper'), findsOneWidget);
    expect(find.text('Second coat'), findsNothing);
    expect(find.text('Seller seller-1'), findsOneWidget);
    expect(app.products.product, same(secondProduct));
    expect(
      repository.calls.where((call) => call.limit == 1),
      hasLength(2),
      reason: 'Each detail route should fetch its identity only once.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('seller identity has a labelled 48px target separate from charity', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SellerInformation(
            user: UserInformation(
              username: 'Alex',
              location: '',
              reviewsCount: 0,
              followersCount: 0,
              followingCount: 0,
              rating: 0,
              awards: 0,
              hasBuyerDiscounts: false,
            ),
            onViewProfile: () => taps += 1,
            charity: Image.asset(AppImages.product1, key: const ValueKey('charity')),
          ),
        ),
      ),
    );
    final target = find.byKey(const ValueKey('seller-public-profile'));
    expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('View Alex’s public profile'), findsOneWidget);
    semantics.dispose();
    await tester.tap(find.byKey(const ValueKey('charity')));
    expect(taps, 0);
    await tester.tap(find.text('Alex'));
    expect(taps, 1);
  });
}
