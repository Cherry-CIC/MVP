import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_page.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_page.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:cherry_mvp/features/liked_items/liked_items_page.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:cherry_mvp/features/profile/widgets/profile_listings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

class _CheckoutRepositoryStub implements ICheckoutRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DonationRepositoryStub implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CategoryRepositoryStub implements ICategoryRepository {
  @override
  Future<Result<List<Category>>> fetchCategories() async => Result.success([]);
}

class _CharityRepositoryStub implements ICharityRepository {
  @override
  Future<Result<List<Charity>>> fetchCharities() async => Result.success([]);
}

class _FakeCharityProfileRepository implements ICharityProfileRepository {
  _FakeCharityProfileRepository({required this.charity});

  final Charity charity;
  final requestedIds = <String?>[];
  final requestedNames = <String?>[];

  @override
  Future<Result<Charity>> fetchCharity({
    String? charityId,
    String? charityName,
  }) async {
    requestedIds.add(charityId);
    requestedNames.add(charityName);
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
        products: const [],
        nextCursor: null,
        hasMore: false,
      ),
    );
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
        limit: limit,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

class _FakeProductRepository extends ProductRepository {
  _FakeProductRepository({
    required this.fetchResult,
    this.unlikeResult,
    this.fetchCharitiesResult,
    this.unlikeCharityResult,
  }) : super(const UnexpectedApiService());

  Result<List<Product>> fetchResult;
  Result<ProductLikeUpdate>? unlikeResult;
  Result<List<Charity>>? fetchCharitiesResult;
  Result<CharityLikeUpdate>? unlikeCharityResult;
  int fetchCount = 0;
  int fetchCharitiesCount = 0;

  @override
  Future<Result<ProductLikeUpdate>> likeProduct(Product product) async {
    return Result.success(
      ProductLikeUpdate(liked: true, likes: product.likes + 1),
    );
  }

  @override
  Future<Result<List<Product>>> fetchLikedProducts() async {
    fetchCount += 1;
    return fetchResult;
  }

  @override
  Future<Result<ProductLikeUpdate>> unlikeProduct(String productId) async {
    return unlikeResult ?? Result.success(const ProductLikeUpdate(liked: false, likes: 0));
  }

  @override
  Future<Result<CharityLikeUpdate>> likeCharity(Charity charity) async {
    return Result.success(
      CharityLikeUpdate(
        liked: true,
        likes: charity.likes + 1,
        charity: charity.copyWith(likes: charity.likes + 1),
      ),
    );
  }

  @override
  Future<Result<List<Charity>>> fetchLikedCharities() async {
    fetchCharitiesCount += 1;
    return fetchCharitiesResult ?? Result.success(const <Charity>[]);
  }

  @override
  Future<Result<CharityLikeUpdate>> unlikeCharity(String charityId) async {
    return unlikeCharityResult ??
        Result.success(const CharityLikeUpdate(liked: false, likes: 0));
  }
}

Charity _charity({
  String id = 'ca6tjKqCRurG0hB49Dcp',
  String name = 'WaterAid',
  int likes = 5,
}) {
  return Charity(
    id: id,
    name: name,
    imageUrl: AppImages.waterAidLogo,
    likes: likes,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

Product _product({String id = 'liked-product', String name = 'Liked jacket'}) {
  return Product(
    id: id,
    name: name,
    description: 'A liked test product',
    quality: 'Good',
    productImages: const [AppImages.product1],
    donation: 6,
    price: 7,
    securityFee: 1,
    likes: 0,
    number: 1,
    size: 'M',
    postageSizeId: 'small',
  );
}

Future<NavigationProvider> _pumpLikedItemsPage(
  WidgetTester tester, {
  required _FakeProductRepository repository,
  ProfileListingsViewModel? listingsViewModel,
  ICharityProfileRepository? charityProfileRepository,
}) async {
  final navigator = NavigationProvider();
  final productViewModel = ProductViewModel(
    productRepository: repository,
    navigator: navigator,
  );
  final checkoutViewModel = CheckoutViewModel(
    donationRepository: _DonationRepositoryStub(),
    checkoutRepository: _CheckoutRepositoryStub(),
    navigator: navigator,
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        Provider<ProductRepository>.value(value: repository),
        ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
        ChangeNotifierProvider<CheckoutViewModel>.value(
          value: checkoutViewModel,
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
        if (listingsViewModel != null) ChangeNotifierProvider<ProfileListingsViewModel>.value(value: listingsViewModel),
        if (charityProfileRepository != null)
          Provider<ICharityProfileRepository>.value(value: charityProfileRepository),
      ],
      child: MaterialApp(
        navigatorKey: navigator.navigatorKey,
        onGenerateRoute: AppRoutes.generateRoute,
        home: listingsViewModel == null
            ? const LikedItemsPage()
            : Scaffold(
                body: SingleChildScrollView(
                  child: ProfileListingsSection(onCreateListing: () {}),
                ),
              ),
      ),
    ),
  );
  if (listingsViewModel != null) {
    navigator.navigateTo(AppRoutes.likedItems);
    await tester.pumpAndSettle();
  }
  return navigator;
}

void main() {
  testWidgets('successful Give from Liked returns to existing listings and refreshes them once', (tester) async {
    final repository = _ProfileListingsRepositoryStub()
      ..listings = [
        const SellerListing(id: 'old-listing', name: 'Old listing', imageUrls: [], price: 8),
      ];
    final listingsViewModel = ProfileListingsViewModel(repository: repository);
    addTearDown(listingsViewModel.dispose);
    await listingsViewModel.loadInitialListings();
    final navigator = await _pumpLikedItemsPage(
      tester,
      repository: _FakeProductRepository(fetchResult: Result.success(const <Product>[])),
      listingsViewModel: listingsViewModel,
    );
    final originalListings = tester.element(find.byType(ProfileListingsSection, skipOffstage: false));
    final previousFetchCount = repository.fetchCount;

    await tester.tap(find.text('Give'));
    await tester.pumpAndSettle();
    expect(find.byType(DonationPage), findsOneWidget);

    repository.listings = [
      const SellerListing(id: 'new-listing', name: 'New listing', imageUrls: [], price: 12.5),
      ...repository.listings,
    ];
    // The submission flow returns true only after posting successfully.
    navigator.goBack(true);
    await tester.pumpAndSettle();

    expect(repository.fetchCount, previousFetchCount + 1);
    expect(tester.element(find.byType(ProfileListingsSection)), same(originalListings));
    expect(find.byKey(const ValueKey('new-listing')), findsOneWidget);
    expect(find.byKey(const ValueKey('old-listing')), findsOneWidget);
    expect(find.byType(LikedItemsPage), findsNothing);
    expect(find.byType(DonationPage), findsNothing);
    expect(navigator.navigatorKey.currentState!.canPop(), isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LikedItemsPage), findsNothing);
    expect(find.byType(DonationPage), findsNothing);
  });

  for (final result in [null, false]) {
    testWidgets('unsuccessful Give result $result leaves Liked open without refreshing listings', (tester) async {
      final repository = _ProfileListingsRepositoryStub();
      final listingsViewModel = ProfileListingsViewModel(repository: repository);
      addTearDown(listingsViewModel.dispose);
      await listingsViewModel.loadInitialListings();
      final navigator = await _pumpLikedItemsPage(
        tester,
        repository: _FakeProductRepository(fetchResult: Result.success(const <Product>[])),
        listingsViewModel: listingsViewModel,
      );
      final previousFetchCount = repository.fetchCount;

      await tester.tap(find.text('Give'));
      await tester.pumpAndSettle();
      navigator.goBack(result);
      await tester.pumpAndSettle();

      expect(find.byType(LikedItemsPage), findsOneWidget);
      expect(find.byType(DonationPage), findsNothing);
      expect(repository.fetchCount, previousFetchCount);
      expect(navigator.navigatorKey.currentState!.canPop(), isTrue);
    });
  }

  testWidgets('LikedItemsPage shows an empty state', (tester) async {
    await _pumpLikedItemsPage(
      tester,
      repository: _FakeProductRepository(
        fetchResult: Result.success(const <Product>[]),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.likedItemsTitle), findsOneWidget);
    expect(find.text(AppStrings.likedItemsEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.likedItemsBrowseProducts), findsOneWidget);
  });

  testWidgets('LikedItemsPage shows an error state and retry action', (
    tester,
  ) async {
    final repository = _FakeProductRepository(
      fetchResult: Result.failure(AppStrings.likedItemsLoadError),
    );

    await _pumpLikedItemsPage(tester, repository: repository);
    await tester.pump();

    expect(find.text(AppStrings.likedItemsLoadError), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);

    repository.fetchResult = Result.success(const <Product>[]);
    await tester.tap(find.text(AppStrings.retry));
    await tester.pump();

    expect(repository.fetchCount, 2);
    expect(find.text(AppStrings.likedItemsEmptyTitle), findsOneWidget);
  });

  testWidgets('LikedItemsPage displays liked product cards', (tester) async {
    await _pumpLikedItemsPage(
      tester,
      repository: _FakeProductRepository(
        fetchResult: Result.success([_product()]),
      ),
    );
    await tester.pump();

    expect(find.byType(ProductCard), findsOneWidget);
    expect(find.text('Liked jacket'), findsOneWidget);
    expect(find.byKey(const ValueKey('product-like-liked-product')), findsOneWidget);
  });

  testWidgets('tapping a liked product opens the existing product page', (
    tester,
  ) async {
    await _pumpLikedItemsPage(
      tester,
      repository: _FakeProductRepository(
        fetchResult: Result.success([_product()]),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(ProductCard));
    await tester.pumpAndSettle();

    expect(find.byType(ProductPage), findsOneWidget);
  });

  testWidgets('unliking a product removes its card after success', (
    tester,
  ) async {
    await _pumpLikedItemsPage(
      tester,
      repository: _FakeProductRepository(
        fetchResult: Result.success([_product()]),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('product-like-liked-product')));
    await tester.pumpAndSettle();

    expect(find.text('Liked jacket'), findsNothing);
    expect(find.text(AppStrings.likedItemsEmptyTitle), findsOneWidget);
  });

  testWidgets('failed unlike keeps the product card visible', (tester) async {
    await _pumpLikedItemsPage(
      tester,
      repository: _FakeProductRepository(
        fetchResult: Result.success([_product()]),
        unlikeResult: Result.failure('Unlike failed'),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('product-like-liked-product')));
    await tester.pumpAndSettle();

    expect(find.text('Liked jacket'), findsOneWidget);
  });

  testWidgets('slider switches between Liked items and Liked charities with empty state for each', (
    tester,
  ) async {
    final repository = _FakeProductRepository(
      fetchResult: Result.success(const <Product>[]),
      fetchCharitiesResult: Result.success(const <Charity>[]),
    );

    await _pumpLikedItemsPage(tester, repository: repository);
    await tester.pump();

    expect(find.byType(LikedItemsSelectionBar), findsOneWidget);
    expect(find.text(AppStrings.likedItemsTab), findsOneWidget);
    expect(find.text(AppStrings.likedCharitiesTab), findsOneWidget);
    expect(find.text(AppStrings.likedItemsEmptyTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.likedCharitiesTab));
    await tester.pumpAndSettle();

    expect(repository.fetchCharitiesCount, 1);
    expect(find.text(AppStrings.likedCharitiesEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.likedCharitiesBrowseCharities), findsOneWidget);

    await tester.tap(find.text(AppStrings.likedItemsTab));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.likedItemsEmptyTitle), findsOneWidget);
  });

  testWidgets('Liked charities tab displays real liked charities and removes charity on unlike', (
    tester,
  ) async {
    final repository = _FakeProductRepository(
      fetchResult: Result.success([_product()]),
      fetchCharitiesResult: Result.success([_charity(likes: 5)]),
    );

    await _pumpLikedItemsPage(tester, repository: repository);
    await tester.pump();

    expect(find.text('Liked jacket'), findsOneWidget);

    await tester.tap(find.text(AppStrings.likedCharitiesTab));
    await tester.pumpAndSettle();

    expect(find.text('WaterAid'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    final likeButton = find.byKey(const ValueKey('discover-charity-like-WaterAid'));
    await tester.ensureVisible(likeButton);
    await tester.pumpAndSettle();
    await tester.tap(likeButton);
    await tester.pumpAndSettle();

    expect(find.text('WaterAid'), findsNothing);
    expect(find.text(AppStrings.likedCharitiesEmptyTitle), findsOneWidget);
  });

  testWidgets('failed charity unlike keeps the charity card visible', (
    tester,
  ) async {
    final repository = _FakeProductRepository(
      fetchResult: Result.success(const <Product>[]),
      fetchCharitiesResult: Result.success([_charity(likes: 2)]),
      unlikeCharityResult: Result.failure('Charity unlike failed'),
    );

    await _pumpLikedItemsPage(tester, repository: repository);
    await tester.pump();

    await tester.tap(find.text(AppStrings.likedCharitiesTab));
    await tester.pumpAndSettle();

    expect(find.text('WaterAid'), findsOneWidget);

    final likeButton = find.byKey(const ValueKey('discover-charity-like-WaterAid'));
    await tester.ensureVisible(likeButton);
    await tester.pumpAndSettle();
    await tester.tap(likeButton);
    await tester.pumpAndSettle();

    expect(find.text('WaterAid'), findsOneWidget);
    expect(find.text('Charity unlike failed'), findsOneWidget);
  });

  testWidgets('tapping a liked charity picture or logo opens CharityProfilePage', (
    tester,
  ) async {
    final waterAid = _charity(likes: 5);
    final profileRepository = _FakeCharityProfileRepository(charity: waterAid);
    final repository = _FakeProductRepository(
      fetchResult: Result.success(const <Product>[]),
      fetchCharitiesResult: Result.success([waterAid]),
    );

    final navigator = await _pumpLikedItemsPage(
      tester,
      repository: repository,
      charityProfileRepository: profileRepository,
    );
    await tester.pump();

    await tester.tap(find.text(AppStrings.likedCharitiesTab));
    await tester.pumpAndSettle();

    // Tapping the charity cover image navigates directly to CharityProfilePage.
    final coverImage = find.byKey(const ValueKey('discover-charity-image-WaterAid'));
    await tester.ensureVisible(coverImage);
    await tester.pumpAndSettle();
    await tester.tap(coverImage);
    await tester.pumpAndSettle();

    expect(find.byType(CharityProfilePage), findsOneWidget);
    expect(profileRepository.requestedIds, [waterAid.id]);
    expect(profileRepository.requestedNames, ['WaterAid']);

    navigator.goBack();
    await tester.pumpAndSettle();
    expect(find.byType(LikedItemsPage), findsOneWidget);

    // Tapping the charity logo badge also navigates directly to CharityProfilePage.
    final logoBadge = find.byKey(const ValueKey('discover-charity-logo-WaterAid'));
    await tester.ensureVisible(logoBadge);
    await tester.pumpAndSettle();
    await tester.tap(logoBadge);
    await tester.pumpAndSettle();

    expect(find.byType(CharityProfilePage), findsOneWidget);
    expect(profileRepository.requestedIds, [waterAid.id, waterAid.id]);
    expect(profileRepository.requestedNames, ['WaterAid', 'WaterAid']);
  });
}
