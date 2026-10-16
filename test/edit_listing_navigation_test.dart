import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form_field.dart';
import 'package:cherry_mvp/features/home/home_repository.dart' as home;
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_draft.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_page.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_repository.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/unexpected_api_service.dart';

class _Products extends ProductRepository {
  _Products(this.current) : super(const UnexpectedApiService());
  Product current;
  bool fail = false;
  @override
  Future<Result<Product>> fetchProduct(String productId) async =>
      fail ? Result.failure('Unavailable') : Result.success(current);
}

class _Editor implements IEditListingRepository {
  _Editor(this.products, this.uid);
  final _Products products;
  final String uid;
  int writes = 0;
  @override
  bool canEdit(Product p) => p.userId == uid && p.status == 'active' && p.number > 0 && p.editVersion != null;
  @override
  Future<Result<Product>> load(String id) async =>
      canEdit(products.current) ? Result.success(products.current) : Result.failure('Not editable');
  @override
  Future<EditListingSaveResult> save(Product original, EditListingDraft draft) async {
    writes++;
    products.current = _product(name: draft.name, version: 2);
    return EditListingSaveResult.success(products.current);
  }
}

class _Home implements home.IHomeRepository {
  int reads = 0;
  @override
  Future<Result<home.ProductPage>> fetchProducts({int limit = 20, String? cursor, String? search}) async {
    reads++;
    return Result.success(const home.ProductPage(products: [], limit: 20, nextCursor: null, hasMore: false));
  }
}

class _Profile implements IProfileListingsRepository {
  int reads = 0;
  @override
  Future<Result<ProfileListingsPage>> fetchListings({int limit = 20, String? cursor}) async {
    reads++;
    return Result.success(const ProfileListingsPage(listings: [], limit: 20, nextCursor: null, hasMore: false));
  }
}

class _Checkout implements ICheckoutRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Donations implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<({_Editor editor, _Home home, _Profile profile, CheckoutViewModel checkout, ProductViewModel productVm})> _open(
  WidgetTester tester,
  _Products products, {
  String uid = 'seller',
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final nav = NavigationProvider();
  final editor = _Editor(products, uid);
  final homeRepo = _Home();
  final profile = _Profile();
  final productVm = ProductViewModel(productRepository: products, navigator: nav, currentUserIdProvider: () => uid)
    ..setProduct(products.current);
  final checkout = CheckoutViewModel(
    donationRepository: _Donations(),
    checkoutRepository: _Checkout(),
    navigator: nav,
    currentUserIdProvider: () => uid,
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: nav),
        Provider<IEditListingRepository>.value(value: editor),
        ChangeNotifierProvider.value(value: productVm),
        ChangeNotifierProvider.value(value: checkout),
        ChangeNotifierProvider(create: (_) => HomeViewModel(homeRepository: homeRepo)),
        ChangeNotifierProvider(create: (_) => ProfileListingsViewModel(repository: profile)),
      ],
      child: MaterialApp(
        navigatorKey: nav.navigatorKey,
        home: const ProductPage(productId: 'listing'),
        onGenerateRoute: (settings) => settings.name == AppRoutes.checkout
            ? MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Checkout destination')),
              )
            : AppRoutes.generateRoute(settings),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (editor: editor, home: homeRepo, profile: profile, checkout: checkout, productVm: productVm);
}

void main() {
  testWidgets('release flag keeps the edit entry point hidden', (tester) async {
    await _open(tester, _Products(_product()));
    expect(find.widgetWithText(FilledButton, 'Edit listing'), findsNothing);
  }, skip: FeatureFlags.enableListingEdit);

  testWidgets('owner opens editor, saves and refreshes detail, profile and feed', (tester) async {
    final products = _Products(_product());
    final harness = await _open(tester, products);
    await tester.tap(find.widgetWithText(FilledButton, 'Edit listing'));
    await tester.pumpAndSettle();
    expect(find.byType(EditListingPage), findsOneWidget);
    final title = find.descendant(
      of: find.byWidgetPredicate((widget) => widget is DonationFormField && widget.title == 'Title'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(title, 'Updated blue jumper');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Save changes');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(harness.editor.writes, 1);
    expect(find.byType(EditListingPage), findsNothing);
    expect(find.text('Updated blue jumper'), findsOneWidget);
    expect(find.text('Listing updated'), findsOneWidget);
    expect(harness.profile.reads, 1);
    expect(harness.home.reads, 1);
    expect(harness.productVm.product?.name, 'Updated blue jumper');
  }, skip: !FeatureFlags.enableListingEdit);

  for (final p in [_product(status: 'sold'), _product(status: null), _product(version: null)]) {
    testWidgets('uneditable listing ${p.status}/${p.editVersion} has no edit button', (tester) async {
      await _open(tester, _Products(p));
      expect(find.widgetWithText(FilledButton, 'Edit listing'), findsNothing);
    }, skip: !FeatureFlags.enableListingEdit);
  }

  testWidgets('buyer must review changed details before entering checkout', (tester) async {
    final products = _Products(_product());
    final harness = await _open(tester, products, uid: 'buyer');
    expect(find.widgetWithText(FilledButton, 'Edit listing'), findsNothing);
    products.current = _product(name: 'Updated blue jumper', version: 2);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.productPageBuyNow));
    await tester.pumpAndSettle();
    expect(find.text('Checkout destination'), findsNothing);
    expect(find.text('Updated blue jumper'), findsOneWidget);
    expect(harness.checkout.basketItems, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.productPageBuyNow));
    await tester.pumpAndSettle();
    expect(find.text('Checkout destination'), findsOneWidget);
    expect(harness.checkout.basketItems.single.editVersion, 2);
  });

  testWidgets('failed purchase refresh cannot start checkout', (tester) async {
    final products = _Products(_product());
    final harness = await _open(tester, products, uid: 'buyer');
    products.fail = true;
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.productPageBuyNow));
    await tester.pumpAndSettle();
    expect(find.text('Checkout destination'), findsNothing);
    expect(harness.checkout.basketItems, isEmpty);
  });
}

Product _product({String name = 'Blue jumper', String? status = 'active', int? version = 1}) => Product(
  id: 'listing',
  userId: 'seller',
  name: name,
  description: 'A blue wool jumper.',
  quality: 'GOOD',
  productImages: const [AppImages.product1],
  donation: 20,
  price: 20,
  securityFee: 2,
  likes: 0,
  number: 1,
  size: 'Medium',
  postageSizeId: 'small',
  status: status,
  editVersion: version,
);
