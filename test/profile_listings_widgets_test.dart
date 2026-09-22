import 'dart:async';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:cherry_mvp/features/profile/widgets/profile_listings_section.dart';
import 'package:cherry_mvp/features/profile/widgets/seller_listing_card.dart';
import 'package:cherry_mvp/features/profile/widgets/user_order_details.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';

import 'support/unexpected_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ProfileListingsRepositoryStub implements IProfileListingsRepository {
  final Result<ProfileListingsPage> result;
  final Future<Result<Product>> Function(String productId)? onFetchProduct;
  final List<String> requestedProductIds = [];

  _ProfileListingsRepositoryStub(this.result, {this.onFetchProduct});

  @override
  Future<Result<ProfileListingsPage>> fetchListings({
    int limit = 20,
    String? cursor,
  }) async {
    return result;
  }

  @override
  Future<Result<Product>> fetchListingProduct(String productId) {
    requestedProductIds.add(productId);
    final fetchProduct = onFetchProduct;
    if (fetchProduct == null) {
      throw StateError('No product response configured');
    }
    return fetchProduct(productId);
  }
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required ProfileListingsViewModel viewModel,
  VoidCallback? onCreateListing,
  double textScale = 1,
  ProductViewModel? productViewModel,
  NavigationProvider? navigator,
  List<String>? pushedRoutes,
}) async {
  final section = MediaQuery(
    data: MediaQueryData.fromView(
      tester.view,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ProfileListingsSection(
          onCreateListing: onCreateListing ?? () {},
        ),
      ),
    ),
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileListingsViewModel>.value(value: viewModel),
        if (productViewModel != null)
          ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
      ],
      child: MaterialApp(
        navigatorKey: navigator?.navigatorKey,
        onGenerateRoute: (settings) {
          pushedRoutes?.add(settings.name ?? '');
          return MaterialPageRoute(
            builder: (_) => Scaffold(body: Text('route: ${settings.name}')),
          );
        },
        home: section,
      ),
    ),
  );
}

void main() {
  testWidgets('seller card shows identifying information and an image fallback', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: SellerListingCard(
              listing: SellerListing(
                id: 'listing-1',
                name: 'Example shirt',
                imageUrls: [],
                price: 12.5,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Example shirt'), findsOneWidget);
    expect(find.text('£12.50'), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('Example shirt. £12.50.'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_outline), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('seller card replaces a failed network image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: SellerListingCard(
              listing: SellerListing(
                id: 'listing-1',
                name: 'Example shirt',
                imageUrls: ['https://example.invalid/unavailable.jpg'],
                price: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('populated listings render in two columns without a button-style header', (tester) async {
    final viewModel = ProfileListingsViewModel(
      repository: _ProfileListingsRepositoryStub(
        Result.success(
          ProfileListingsPage(
            listings: const [
              SellerListing(
                id: 'listing-1',
                name: 'First listing',
                imageUrls: [],
                price: 10,
              ),
              SellerListing(
                id: 'listing-2',
                name: 'Second listing',
                imageUrls: [],
                price: 20,
              ),
            ],
            limit: 20,
            nextCursor: null,
            hasMore: false,
          ),
        ),
      ),
    );
    await viewModel.loadInitialListings();

    await _pumpSection(tester, viewModel: viewModel);

    final firstPosition = tester.getTopLeft(find.text('First listing'));
    final secondPosition = tester.getTopLeft(find.text('Second listing'));
    expect(firstPosition.dy, secondPosition.dy);
    expect(firstPosition.dx, lessThan(secondPosition.dx));
    expect(
      find.ancestor(
        of: find.text(AppStrings.profileUserListings),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets('empty listings explain the state and offer Give', (tester) async {
    var createListingPressed = false;
    final viewModel = ProfileListingsViewModel(
      repository: _ProfileListingsRepositoryStub(
        Result.success(
          const ProfileListingsPage(
            listings: [],
            limit: 20,
            nextCursor: null,
            hasMore: false,
          ),
        ),
      ),
    );
    await viewModel.loadInitialListings();

    await _pumpSection(
      tester,
      viewModel: viewModel,
      onCreateListing: () => createListingPressed = true,
    );
    await tester.tap(find.text(AppStrings.profileListingsCreate));

    expect(find.text(AppStrings.profileListingsEmpty), findsOneWidget);
    expect(createListingPressed, isTrue);
  });

  testWidgets('failed listings show a retry control', (tester) async {
    final viewModel = ProfileListingsViewModel(
      repository: _ProfileListingsRepositoryStub(
        Result.failure('technical failure'),
      ),
    );
    await viewModel.loadInitialListings();

    await _pumpSection(tester, viewModel: viewModel);

    expect(find.text(AppStrings.profileListingsLoadFailed), findsOneWidget);
    expect(find.text('technical failure'), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });

  testWidgets('seller cards tolerate large text without overflowing', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final viewModel = ProfileListingsViewModel(
      repository: _ProfileListingsRepositoryStub(
        Result.success(
          const ProfileListingsPage(
            listings: [
              SellerListing(
                id: 'listing-1',
                name: 'A long listing title that needs more than one line',
                imageUrls: [],
                price: null,
              ),
            ],
            limit: 20,
            nextCursor: null,
            hasMore: false,
          ),
        ),
      ),
    );
    await viewModel.loadInitialListings();

    await _pumpSection(
      tester,
      viewModel: viewModel,
      textScale: 2,
    );

    expect(find.text(AppStrings.profileListingPriceUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile shortcuts contain Orders and Liked but not Listings', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: UserOrderDetails()),
      ),
    );

    expect(find.text(AppStrings.profileUserOrders), findsOneWidget);
    expect(find.text(AppStrings.profileUserLiked), findsOneWidget);
    expect(find.text(AppStrings.profileUserListings), findsNothing);
  });

  testWidgets('tapping an own listing opens the shared product details page', (tester) async {
    final semantics = tester.ensureSemantics();
    final repository = _ProfileListingsRepositoryStub(
      Result.success(
        const ProfileListingsPage(
          listings: [
            SellerListing(
              id: 'listing-1',
              name: 'First listing',
              imageUrls: [],
              price: 10,
            ),
          ],
          limit: 20,
          nextCursor: null,
          hasMore: false,
        ),
      ),
      onFetchProduct: (_) async => Result.success(_product),
    );
    final viewModel = ProfileListingsViewModel(repository: repository);
    await viewModel.loadInitialListings();

    final navigator = NavigationProvider();
    final productViewModel = ProductViewModel(
      productRepository: ProductRepository(const UnexpectedApiService()),
      navigator: navigator,
    );
    final pushedRoutes = <String>[];

    await _pumpSection(
      tester,
      viewModel: viewModel,
      productViewModel: productViewModel,
      navigator: navigator,
      pushedRoutes: pushedRoutes,
    );

    expect(
      find.bySemanticsLabel('First listing. £10.00.'),
      findsOneWidget,
    );

    await tester.tap(find.text('First listing'));
    await tester.pumpAndSettle();

    expect(repository.requestedProductIds, ['listing-1']);
    expect(productViewModel.product?.id, 'product-1');
    expect(pushedRoutes, [AppRoutes.product]);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('a listing that cannot be opened reports the failure and stays put', (tester) async {
    final repository = _ProfileListingsRepositoryStub(
      Result.success(
        const ProfileListingsPage(
          listings: [
            SellerListing(
              id: 'listing-1',
              name: 'First listing',
              imageUrls: [],
              price: 10,
            ),
          ],
          limit: 20,
          nextCursor: null,
          hasMore: false,
        ),
      ),
      onFetchProduct: (_) async => Result.failure('Listing is gone.'),
    );
    final viewModel = ProfileListingsViewModel(repository: repository);
    await viewModel.loadInitialListings();

    final navigator = NavigationProvider();
    final productViewModel = ProductViewModel(
      productRepository: ProductRepository(const UnexpectedApiService()),
      navigator: navigator,
    );
    final pushedRoutes = <String>[];

    await _pumpSection(
      tester,
      viewModel: viewModel,
      productViewModel: productViewModel,
      navigator: navigator,
      pushedRoutes: pushedRoutes,
    );

    await tester.tap(find.text('First listing'));
    await tester.pumpAndSettle();

    expect(find.text('Listing is gone.'), findsOneWidget);
    expect(pushedRoutes, isEmpty);
    expect(productViewModel.product, isNull);
    expect(viewModel.openListingError, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a listing being opened shows progress and ignores further taps', (tester) async {
    final response = Completer<Result<Product>>();
    final repository = _ProfileListingsRepositoryStub(
      Result.success(
        const ProfileListingsPage(
          listings: [
            SellerListing(
              id: 'listing-1',
              name: 'First listing',
              imageUrls: [],
              price: 10,
            ),
          ],
          limit: 20,
          nextCursor: null,
          hasMore: false,
        ),
      ),
      onFetchProduct: (_) => response.future,
    );
    final viewModel = ProfileListingsViewModel(repository: repository);
    await viewModel.loadInitialListings();

    final navigator = NavigationProvider();
    final productViewModel = ProductViewModel(
      productRepository: ProductRepository(const UnexpectedApiService()),
      navigator: navigator,
    );

    await _pumpSection(
      tester,
      viewModel: viewModel,
      productViewModel: productViewModel,
      navigator: navigator,
    );

    await tester.tap(find.text('First listing'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('First listing'));
    await tester.pump();
    expect(repository.requestedProductIds, ['listing-1']);

    response.complete(Result.success(_product));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

}

const _product = Product(
  id: 'product-1',
  userId: 'seller-1',
  name: 'Jumper',
  description: 'Blue jumper',
  quality: 'Good',
  productImages: [],
  donation: 20,
  price: 20,
  securityFee: 2,
  likes: 0,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
);
