import 'dart:async';

import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/liked_items/liked_items_view_model.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/public_profile_fixtures.dart';
import 'support/unexpected_api_service.dart';

class _HomeRepository implements IHomeRepository {
  final responses = <Future<Result<ProductPage>>>[];

  @override
  Future<Result<ProductPage>> fetchProducts({int limit = 20, String? cursor, String? search}) => responses.removeAt(0);
}

class _ListingsRepository implements IProfileListingsRepository {
  final responses = <Future<Result<ProfileListingsPage>>>[];
  var requests = 0;

  @override
  Future<Result<ProfileListingsPage>> fetchListings({int limit = 20, String? cursor}) {
    requests++;
    return responses.removeAt(0);
  }
}

class _ProductRepository extends ProductRepository {
  _ProductRepository() : super(const UnexpectedApiService());

  final responses = <Future<Result<List<Product>>>>[];
  final likeResponse = Completer<Result<ProductLikeUpdate>>();
  final unlikeResponse = Completer<Result<ProductLikeUpdate>>();

  @override
  Future<Result<List<Product>>> fetchLikedProducts() => responses.removeAt(0);

  @override
  Future<Result<ProductLikeUpdate>> likeProduct(Product product) => likeResponse.future;

  @override
  Future<Result<ProductLikeUpdate>> unlikeProduct(String productId) => unlikeResponse.future;
}

ProductPage _homePage(List<String> ids, {bool hasMore = false}) => ProductPage(
  products: ids.map(publicProfileProduct).toList(),
  limit: 20,
  nextCursor: hasMore ? 'next' : null,
  hasMore: hasMore,
);

ProfileListingsPage _listingsPage(List<String> ids, {bool hasMore = false}) => ProfileListingsPage(
  listings: ids.map((id) => SellerListing(id: id, name: id, imageUrls: const [], price: 7)).toList(),
  limit: 20,
  nextCursor: hasMore ? 'next' : null,
  hasMore: hasMore,
);

void main() {
  late DeletedListings deletedListings;

  setUp(() {
    deletedListings = DeletedListings();
  });

  tearDown(() => deletedListings.dispose());

  test('confirmed deletion notifications are idempotent and ignore empty IDs', () {
    var notifications = 0;
    deletedListings.addListener(() => notifications++);
    deletedListings.add('');
    deletedListings.add(' ');
    deletedListings.add('removed');
    deletedListings.add('removed');
    expect(deletedListings.contains('removed'), isTrue);
    expect(deletedListings.contains('other'), isFalse);
    expect(notifications, 1);
  });

  testWidgets('home and search first pages filter deletion completed during their requests', (tester) async {
    final homeResponse = Completer<Result<ProductPage>>();
    final searchResponse = Completer<Result<ProductPage>>();
    final repository = _HomeRepository()..responses.addAll([homeResponse.future, searchResponse.future]);
    final reconciled = <String>[];
    final model = HomeViewModel(
      homeRepository: repository,
      deletedListings: deletedListings,
      onProductsLoaded: (products) => reconciled.addAll(products.map((product) => product.id)),
    );
    addTearDown(model.dispose);
    final loading = model.fetchProducts();
    model.updateSearchText('coat');
    await tester.pump(HomeViewModel.searchDebounceDuration);

    deletedListings.add('removed');
    homeResponse.complete(Result.success(_homePage(['removed', 'home'])));
    searchResponse.complete(Result.success(_homePage(['removed', 'search'])));
    await loading;
    await tester.pump();

    expect(model.products.map((product) => product.id), ['home']);
    expect(model.searchProducts.map((product) => product.id), ['search']);
    expect(reconciled, ['home', 'search']);
  });

  testWidgets('deletion removes loaded feed and search cards and filters late pagination', (tester) async {
    final homeResponse = Completer<Result<ProductPage>>();
    final searchResponse = Completer<Result<ProductPage>>();
    final repository = _HomeRepository()
      ..responses.addAll([
        Future.value(Result.success(_homePage(['removed', 'keep'], hasMore: true))),
        Future.value(Result.success(_homePage(['removed', 'keep'], hasMore: true))),
        homeResponse.future,
        searchResponse.future,
      ]);
    final model = HomeViewModel(homeRepository: repository, deletedListings: deletedListings);
    addTearDown(model.dispose);
    await model.fetchProducts();
    model.updateSearchText('coat');
    await tester.pump(HomeViewModel.searchDebounceDuration);
    final loadingHome = model.loadMoreProducts();
    final loadingSearch = model.loadMoreSearchProducts();

    deletedListings.add('removed');
    expect(model.products.map((product) => product.id), ['keep']);
    expect(model.searchProducts.map((product) => product.id), ['keep']);
    homeResponse.complete(Result.success(_homePage(['removed', 'new-home'])));
    searchResponse.complete(Result.success(_homePage(['removed', 'new-search'])));
    await Future.wait([loadingHome, loadingSearch]);
    expect(model.products.map((product) => product.id), ['keep', 'new-home']);
    expect(model.searchProducts.map((product) => product.id), ['keep', 'new-search']);
  });

  test('profile first-page response cannot restore a confirmed deletion', () async {
    final response = Completer<Result<ProfileListingsPage>>();
    final repository = _ListingsRepository()..responses.add(response.future);
    final model = ProfileListingsViewModel(repository: repository, deletedListings: deletedListings);
    addTearDown(model.dispose);
    final loading = model.loadInitialListings();
    deletedListings.add('removed');
    response.complete(Result.success(_listingsPage(['removed', 'keep'])));
    await loading;
    expect(model.listings.map((listing) => listing.id), ['keep']);
  });

  for (final throwsError in [false, true]) {
    test('profile preserves deletion and exposes refresh failure, thrown: $throwsError', () async {
      final pagination = Completer<Result<ProfileListingsPage>>();
      final refreshResponse = Completer<Result<ProfileListingsPage>>();
      final repository = _ListingsRepository()
        ..responses.addAll([
          Future.value(Result.success(_listingsPage(['removed', 'keep'], hasMore: true))),
          pagination.future,
          refreshResponse.future,
          Future.value(Result.success(_listingsPage(['removed', 'keep']))),
        ]);
      final model = ProfileListingsViewModel(repository: repository, deletedListings: deletedListings);
      addTearDown(model.dispose);
      await model.loadInitialListings();
      final loadingMore = model.loadMoreListings();
      deletedListings.add('removed');
      pagination.complete(Result.success(_listingsPage(['removed', 'new'])));
      await loadingMore;
      expect(model.listings.map((listing) => listing.id), ['keep', 'new']);

      final refreshing = model.refreshListings();
      if (throwsError) {
        refreshResponse.completeError(StateError('network failed'));
      } else {
        refreshResponse.complete(Result.failure('network failed'));
      }
      await refreshing;
      expect(model.listings.map((listing) => listing.id), ['keep', 'new']);
      expect(model.hasRefreshError, isTrue);
      expect(model.status.type, StatusType.success);
      await model.refreshListings();
      expect(model.hasRefreshError, isFalse);
      expect(model.listings.map((listing) => listing.id), ['keep']);
    });
  }

  test('profile rejects a response after the account changes without an auth notification', () async {
    var accountId = 'account-a';
    final response = Completer<Result<ProfileListingsPage>>();
    final repository = _ListingsRepository()..responses.add(response.future);
    final model = ProfileListingsViewModel(
      repository: repository,
      deletedListings: deletedListings,
      currentUserIdProvider: () => accountId,
    );
    addTearDown(model.dispose);
    final loading = model.loadInitialListings();
    accountId = 'account-b';
    response.complete(Result.success(_listingsPage(['account-a-listing'])));
    await loading;
    expect(model.accountOwnerId, 'account-b');
    expect(model.listings, isEmpty);
    expect(model.status.type, StatusType.uninitialized);
  });

  test('profile auth notifications invalidate an old request even after switching back', () async {
    String? accountId = 'account-a';
    final response = Completer<Result<ProfileListingsPage>>();
    final repository = _ListingsRepository()
      ..responses.addAll([
        Future.value(Result.success(_listingsPage(['removed'], hasMore: true))),
        response.future,
        Future.value(Result.success(_listingsPage(['removed', 'new']))),
      ]);
    final model = ProfileListingsViewModel(
      repository: repository,
      deletedListings: deletedListings,
      currentUserIdProvider: () => accountId,
    );
    addTearDown(model.dispose);
    await model.loadInitialListings();
    final loading = model.loadMoreListings();
    accountId = null;
    model.updateCurrentAccount();
    await model.loadInitialListings();
    expect(repository.requests, 2);
    expect(model.listings, isEmpty);
    deletedListings.add('removed');
    accountId = 'account-a';
    model.updateCurrentAccount();
    await model.loadInitialListings();
    response.complete(Result.success(_listingsPage(['stale'])));
    await loading;
    expect(model.accountOwnerId, 'account-a');
    expect(model.listings.map((listing) => listing.id), ['new']);
  });

  test('selected details, liked state and cached counts stay removed after stale updates', () async {
    final repository = _ProductRepository();
    final product = publicProfileProduct('removed');
    final model = ProductViewModel(
      productRepository: repository,
      navigator: NavigationProvider(),
      deletedListings: deletedListings,
    );
    addTearDown(model.dispose);
    model.setProduct(product);
    model.cacheLikedProducts([product]);
    final like = model.setProductLiked(product, true);
    expect(model.isLikeUpdatePending(product.id), isTrue);
    deletedListings.add(product.id);
    expect(model.product, isNull);
    expect(model.cachedLikedProducts, isEmpty);
    expect(model.isProductLiked(product.id), isFalse);
    expect(model.isLikeUpdatePending(product.id), isFalse);

    repository.likeResponse.complete(Result.success(const ProductLikeUpdate(liked: true, likes: 5)));
    expect((await like).isSuccess, isFalse);
    model.setProduct(product);
    model.applyListingUpdate(product);
    model.cacheLikedProducts([product]);
    model.setCachedLikeState(product.id, true);
    model.clearUserState();
    model.setProduct(product);
    expect(model.product, isNull);
    expect(model.cachedLikedProducts, isEmpty);
    expect(model.getLikesCount(product), 0);
    expect(model.isProductLiked(product.id), isFalse);
  });

  test('liked-items hydration and an open liked list filter late deleted products', () async {
    final hydrationResponse = Completer<Result<List<Product>>>();
    final likedResponse = Completer<Result<List<Product>>>();
    final repository = _ProductRepository()..responses.addAll([hydrationResponse.future, likedResponse.future]);
    final productModel = ProductViewModel(
      productRepository: repository,
      navigator: NavigationProvider(),
      deletedListings: deletedListings,
    );
    final likedModel = LikedItemsViewModel(
      productRepository: repository,
      productViewModel: productModel,
      deletedListings: deletedListings,
    );
    addTearDown(likedModel.dispose);
    addTearDown(productModel.dispose);
    final hydrating = productModel.hydrateLikedProducts();
    final loading = likedModel.loadLikedProducts();
    deletedListings.add('removed');
    final products = [publicProfileProduct('removed'), publicProfileProduct('keep')];
    hydrationResponse.complete(Result.success(products));
    likedResponse.complete(Result.success(products));
    await Future.wait([hydrating, loading]);
    expect(likedModel.products.map((product) => product.id), ['keep']);
    expect(productModel.cachedLikedProducts.map((product) => product.id), ['keep']);
    deletedListings.add('keep');
    expect(likedModel.products, isEmpty);
    expect(likedModel.status, LikedItemsStatus.empty);
    expect(productModel.cachedLikedProducts, isEmpty);
  });

  test('deletion during an unlike request cannot remove a different liked item', () async {
    final products = [publicProfileProduct('first'), publicProfileProduct('unlike'), publicProfileProduct('keep')];
    final repository = _ProductRepository()..responses.add(Future.value(Result.success(products)));
    final productModel = ProductViewModel(
      productRepository: repository,
      navigator: NavigationProvider(),
      deletedListings: deletedListings,
    );
    final likedModel = LikedItemsViewModel(
      productRepository: repository,
      productViewModel: productModel,
      deletedListings: deletedListings,
    );
    addTearDown(likedModel.dispose);
    addTearDown(productModel.dispose);
    await likedModel.loadLikedProducts();
    final unliking = likedModel.unlikeProduct(products[1]);
    deletedListings.add('first');
    repository.unlikeResponse.complete(Result.success(const ProductLikeUpdate(liked: false, likes: 0)));
    expect(await unliking, isTrue);
    expect(likedModel.products.map((product) => product.id), ['keep']);
  });

  for (final pagination in [false, true]) {
    test('public profile filters deletion during ${pagination ? 'pagination' : 'first page'}', () async {
      final response = Completer<Result<PublicUserProfilePage>>();
      final repository = FakePublicProfileRepository(
        (_, cursor) => pagination && cursor == null
            ? Result.success(publicProfilePage(products: [publicProfileProduct('removed')], cursor: 'next'))
            : response.future,
      );
      final model = PublicUserProfileViewModel(
        userId: 'seller',
        repository: repository,
        deletedListings: deletedListings,
      );
      addTearDown(model.dispose);
      late Future<void> loading;
      if (pagination) {
        await model.loadProfile();
        loading = model.loadMore();
      } else {
        loading = model.loadProfile();
      }
      deletedListings.add('removed');
      expect(model.products, isEmpty);
      response.complete(
        Result.success(publicProfilePage(products: [publicProfileProduct('removed'), publicProfileProduct('keep')])),
      );
      await loading;
      expect(model.products.map((product) => product.id), ['keep']);
      expect(model.status, PublicProfileStatus.ready);
    });
  }

  test('disposed feed, profile and liked views ignore late reads and deletion events', () async {
    final homeResponse = Completer<Result<ProductPage>>();
    final profileResponse = Completer<Result<ProfileListingsPage>>();
    final likedResponse = Completer<Result<List<Product>>>();
    final productRepository = _ProductRepository()..responses.add(likedResponse.future);
    final productModel = ProductViewModel(
      productRepository: productRepository,
      navigator: NavigationProvider(),
      deletedListings: deletedListings,
    );
    final homeModel = HomeViewModel(
      homeRepository: _HomeRepository()..responses.add(homeResponse.future),
      deletedListings: deletedListings,
    );
    final profileModel = ProfileListingsViewModel(
      repository: _ListingsRepository()..responses.add(profileResponse.future),
      deletedListings: deletedListings,
    );
    final likedModel = LikedItemsViewModel(
      productRepository: productRepository,
      productViewModel: productModel,
      deletedListings: deletedListings,
    );
    final loading = [homeModel.fetchProducts(), profileModel.loadInitialListings(), likedModel.loadLikedProducts()];
    homeModel.dispose();
    profileModel.dispose();
    likedModel.dispose();
    productModel.dispose();
    deletedListings.add('removed');
    homeResponse.complete(Result.success(_homePage(['removed'])));
    profileResponse.complete(Result.success(_listingsPage(['removed'])));
    likedResponse.complete(Result.success([publicProfileProduct('removed')]));
    await Future.wait(loading);
    expect(homeModel.products, isEmpty);
    expect(profileModel.listings, isEmpty);
    expect(likedModel.products, isEmpty);
  });
}
