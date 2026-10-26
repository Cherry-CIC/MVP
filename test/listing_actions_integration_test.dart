import 'dart:async';

import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/home/home_repository.dart' as home;
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/delete_listing_view_model.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_draft.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_repository.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/listing_actions_menu.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:cherry_mvp/features/profile/widgets/profile_listings_section.dart';
import 'package:cherry_mvp/features/profile/widgets/seller_listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/unexpected_api_service.dart';

const _product = Product(
  id: 'listing',
  userId: 'seller',
  name: 'Blue jacket',
  description: 'A blue denim jacket',
  quality: 'GOOD',
  productImages: [AppImages.product1],
  donation: 10,
  price: 10,
  securityFee: 1,
  likes: 0,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
  status: 'active',
);

class _Products extends ProductRepository {
  _Products(DeletedListings deleted) : super(const UnexpectedApiService(), deletedListings: deleted);
  Product current = _product;
  int reads = 0;
  int deletes = 0;
  Future<Result<void>> Function() respond = () async => Result.success(null, statusCode: 200);
  @override
  Future<Result<Product>> fetchProduct(String id) async {
    reads++;
    return Result.success(current);
  }

  @override
  Future<Result<void>> deleteProduct(String id) {
    deletes++;
    return respond();
  }
}

class _Profile implements IProfileListingsRepository {
  _Profile({this.sold = false});
  final bool sold;
  int reads = 0;
  bool failRefresh = false;
  @override
  Future<Result<ProfileListingsPage>> fetchListings({int limit = 20, String? cursor}) async {
    reads++;
    if (failRefresh) return Result.failure('Temporary failure');
    return Result.success(
      ProfileListingsPage(
        listings: [
          SellerListing(
            id: 'listing',
            name: 'Blue jacket',
            imageUrls: const [],
            price: 10,
            userId: 'seller',
            status: sold ? 'sold' : 'active',
            number: sold ? 0 : 1,
          ),
        ],
        limit: 20,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

class _Home implements home.IHomeRepository {
  int reads = 0;
  @override
  Future<Result<home.ProductPage>> fetchProducts({int limit = 20, String? cursor, String? search}) async {
    reads++;
    return Result.success(const home.ProductPage(products: [_product], limit: 20, nextCursor: null, hasMore: false));
  }
}

class _Edit implements IEditListingRepository {
  _Edit(this.uid);
  final String Function() uid;
  @override
  bool canEdit(Product p) => p.userId == uid() && p.number > 0 && (p.status == 'active' || p.status == 'unlisted');
  @override
  Future<Result<Product>> load(String id) async => Result.success(_product);
  @override
  Future<EditListingSaveResult> save(Product original, EditListingDraft draft) => throw UnimplementedError();
}

class _Checkout implements ICheckoutRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Donation implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Harness {
  _Harness({this.uid = 'seller', bool sold = false}) {
    products = _Products(deleted);
    profileRepo = _Profile(sold: sold);
    profile = ProfileListingsViewModel(
      repository: profileRepo,
      deletedListings: deleted,
      currentUserIdProvider: () => uid,
    );
    productVm = ProductViewModel(
      productRepository: products,
      navigator: nav,
      deletedListings: deleted,
      currentUserIdProvider: () => uid,
    );
    homeVm = HomeViewModel(homeRepository: homeRepo, deletedListings: deleted);
    deletion = DeleteListingViewModel(
      repository: products,
      deletedListings: deleted,
      currentUserId: () => uid,
    );
    checkout = CheckoutViewModel(
      checkoutRepository: _Checkout(),
      donationRepository: _Donation(),
      navigator: nav,
      currentUserIdProvider: () => uid,
    );
  }
  String uid;
  final nav = NavigationProvider();
  final deleted = DeletedListings();
  final homeRepo = _Home();
  late final _Products products;
  late final _Profile profileRepo;
  late final ProfileListingsViewModel profile;
  late final ProductViewModel productVm;
  late final HomeViewModel homeVm;
  late final DeleteListingViewModel deletion;
  late final CheckoutViewModel checkout;
  final visited = <String?>[];

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    SharedPreferences.setMockInitialValues({});
    await profile.loadInitialListings();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: nav),
          Provider<IEditListingRepository>.value(value: _Edit(() => uid)),
          ChangeNotifierProvider.value(value: deleted),
          ChangeNotifierProvider.value(value: productVm),
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: homeVm),
          ChangeNotifierProvider.value(value: deletion),
          ChangeNotifierProvider.value(value: checkout),
        ],
        child: MaterialApp(
          navigatorKey: nav.navigatorKey,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ProfileListingsSection(onCreateListing: () {}),
            ),
          ),
          onGenerateRoute: (settings) {
            visited.add(settings.name);
            if (settings.name == AppRoutes.myListings ||
                settings.name == AppRoutes.editListing ||
                settings.name == AppRoutes.login) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => Scaffold(body: Text('Destination ${settings.name}')),
              );
            }
            return AppRoutes.generateRoute(settings);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _chooseDelete(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Manage Blue jacket'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete listing'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('owner menu is a separate accessible 48px target at top right of photo', (tester) async {
    final semantics = tester.ensureSemantics();

    final h = _Harness();
    await h.pump(tester);
    final card = tester.getRect(find.byType(SellerListingCard));
    final menu = tester.getRect(find.byType(ListingActionsMenu));
    expect(menu.size, const Size.square(48));
    expect(menu.top - card.top, 8);
    expect(card.right - menu.right, 8);
    expect(tester.getSemantics(find.byTooltip('Manage Blue jacket')).getSemanticsData().tooltip, 'Manage Blue jacket');
    await tester.tap(find.byTooltip('Manage Blue jacket'));
    await tester.pumpAndSettle();
    expect(find.text('Edit listing'), findsOneWidget);
    expect(find.text('Delete listing'), findsOneWidget);
    expect(find.byType(ProductPage), findsNothing);
    await tester.tap(find.text('Edit listing'));
    await tester.pumpAndSettle();
    expect(h.visited, [AppRoutes.editListing]);
    semantics.dispose();
  });

  testWidgets('card deletion stays removed after refresh failure and shows refresh retry', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await _chooseDelete(tester);
    h.profileRepo.failRefresh = true;
    await tester.tap(find.widgetWithText(FilledButton, 'Delete listing'));
    await tester.pumpAndSettle();
    expect(h.products.deletes, 1);
    expect(find.text('Listing deleted'), findsOneWidget);
    expect(find.byType(SellerListingCard), findsNothing);
    expect(find.text('Refresh again'), findsOneWidget);
    h.profileRepo.failRefresh = false;
    await tester.tap(find.text('Refresh again'));
    await tester.pumpAndSettle();
    expect(find.byType(SellerListingCard), findsNothing);
    expect(h.homeRepo.reads, 1);
  });

  testWidgets('deletion from own details returns to existing listings and rejects stale refresh', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(find.text('Blue jacket'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductPage), findsOneWidget);
    await _chooseDelete(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete listing'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductPage), findsNothing);
    expect(find.byType(ProfileListingsSection), findsOneWidget);
    expect(find.byType(SellerListingCard), findsNothing);
    expect(find.text('Listing deleted'), findsOneWidget);
    expect(h.products.deletes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deletion opened outside own profile navigates to own listings', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    unawaited(h.nav.navigateTo(AppRoutes.product, arguments: _product));
    await tester.pumpAndSettle();
    await _chooseDelete(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete listing'));
    await tester.pumpAndSettle();
    expect(find.text('Destination ${AppRoutes.myListings}'), findsOneWidget);
    expect(find.byType(ProductPage), findsNothing);
  });

  testWidgets('403 refreshes a Product argument route before the dialogue is dismissed', (tester) async {
    final h = _Harness();
    h.products.respond = () async => Result.failure('Ignored', statusCode: 403, errorCode: 'LISTING_NOT_OWNER');
    await h.pump(tester);
    unawaited(h.nav.navigateTo(AppRoutes.product, arguments: _product));
    await tester.pumpAndSettle();
    await _chooseDelete(tester);
    h.products.current = Product.fromJson({..._product.toJson(), 'userId': 'someone-else'});
    await tester.tap(find.widgetWithText(FilledButton, 'Delete listing'));
    await tester.pumpAndSettle();
    expect(h.products.reads, 1);
    expect(h.profileRepo.reads, 2);
    expect(h.deleted.contains('listing'), isFalse);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Manage Blue jacket'), findsNothing);
  });

  testWidgets('401 offers the existing sign-in route', (tester) async {
    final h = _Harness();
    h.products.respond = () async => Result.failure('Ignored', statusCode: 401);
    await h.pump(tester);
    await _chooseDelete(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete listing'));
    await tester.pumpAndSettle();
    expect(find.text(DeleteListingOutcome.unauthenticated.message), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(h.deleted.contains('listing'), isFalse);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(h.visited, [AppRoutes.login]);
  });

  for (final sold in [true, false]) {
    testWidgets('no owner menu for ${sold ? 'sold listing' : 'another owner'}', (tester) async {
      final h = _Harness(sold: sold, uid: sold ? 'seller' : 'buyer');
      await h.pump(tester);
      expect(find.byType(ListingActionsMenu), findsNothing);
    });
  }

  testWidgets('owner cards and menus support large text on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = _Harness();
    await h.pump(tester, textScale: 2.5);
    await _chooseDelete(tester);
    expect(find.text('Delete this listing?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
