import 'dart:async';

import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/liked_items/liked_items_view_model.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/unexpected_api_service.dart';

class _HomeRepository implements IHomeRepository {
  final responses = <Future<Result<ProductPage>>>[];
  final requests = <({String? cursor, String? search})>[];

  @override
  Future<Result<ProductPage>> fetchProducts({int limit = 20, String? cursor, String? search}) {
    requests.add((cursor: cursor, search: search));
    return responses.removeAt(0);
  }
}

class _ListingsRepository implements IProfileListingsRepository {
  final responses = <Future<Result<ProfileListingsPage>>>[];

  @override
  Future<Result<ProfileListingsPage>> fetchListings({int limit = 20, String? cursor}) {
    return responses.removeAt(0);
  }
}

class _ProductRepository extends ProductRepository {
  _ProductRepository() : super(const UnexpectedApiService());

  final responses = <Future<Result<List<Product>>>>[];

  @override
  Future<Result<List<Product>>> fetchLikedProducts() => responses.removeAt(0);
}

class _NavigationProvider extends NavigationProvider {
  String? route;
  Object? arguments;

  @override
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) async {
    route = routeName;
    this.arguments = arguments;
  }
}

void main() {
  group('Listing edit cache refresh', () {
    testWidgets('home and search discard cached cards and pre-edit responses', (tester) async {
      final oldProduct = _product(name: 'Old coat', version: 1);
      final savedProduct = _product(name: 'Updated coat', version: 2);
      final staleHome = Completer<Result<ProductPage>>();
      final staleSearch = Completer<Result<ProductPage>>();
      final freshHome = Completer<Result<ProductPage>>();
      final freshSearch = Completer<Result<ProductPage>>();
      final repository = _HomeRepository()
        ..responses.addAll([
          Future.value(Result.success(_homePage(oldProduct))),
          Future.value(Result.success(_homePage(oldProduct, hasMore: true))),
          staleHome.future,
          staleSearch.future,
          freshHome.future,
          freshSearch.future,
        ]);
      final viewModel = HomeViewModel(homeRepository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.fetchProducts();
      viewModel.updateSearchText('coat');
      await tester.pump(HomeViewModel.searchDebounceDuration);
      expect(viewModel.searchProducts, [oldProduct]);

      final oldHomeRequest = viewModel.refreshProducts();
      final oldSearchRequest = viewModel.loadMoreSearchProducts();
      final refresh = viewModel.refreshAfterListingEdit();

      expect(viewModel.products, isEmpty);
      expect(viewModel.searchProducts, isEmpty);
      expect(viewModel.searchQuery, 'coat');
      expect(viewModel.searchText, 'coat');
      expect(viewModel.status.type, StatusType.loading);
      expect(viewModel.searchStatus.type, StatusType.loading);
      expect(viewModel.isLoadingMoreSearch, isFalse);
      expect(repository.requests.skip(4), [
        (cursor: null, search: null),
        (cursor: null, search: 'coat'),
      ]);

      freshHome.complete(Result.success(_homePage(savedProduct)));
      freshSearch.complete(Result.success(_homePage(savedProduct)));
      await refresh;
      staleHome.complete(Result.success(_homePage(oldProduct, hasMore: true)));
      staleSearch.complete(Result.success(_homePage(oldProduct, hasMore: true)));
      await Future.wait([oldHomeRequest, oldSearchRequest]);

      expect(viewModel.products, [savedProduct]);
      expect(viewModel.searchProducts, [savedProduct]);
      expect(viewModel.hasMore, isFalse);
      expect(viewModel.searchHasMore, isFalse);
      expect(viewModel.isRefreshing, isFalse);
    });

    testWidgets('pending search debounce is replaced once and refresh failure cannot restore old cards', (
      tester,
    ) async {
      final oldProduct = _product(name: 'Old coat', version: 1);
      final staleHome = Completer<Result<ProductPage>>();
      final freshHome = Completer<Result<ProductPage>>();
      final freshSearch = Completer<Result<ProductPage>>();
      final repository = _HomeRepository()
        ..responses.addAll([
          Future.value(Result.success(_homePage(oldProduct))),
          staleHome.future,
          freshHome.future,
          freshSearch.future,
        ]);
      final viewModel = HomeViewModel(homeRepository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.fetchProducts();
      final oldHomeRequest = viewModel.refreshProducts();
      viewModel.updateSearchText('new search');
      final refresh = viewModel.refreshAfterListingEdit();
      await tester.pump(HomeViewModel.searchDebounceDuration);
      expect(repository.requests, hasLength(4));

      staleHome.complete(Result.success(_homePage(oldProduct)));
      await oldHomeRequest;
      expect(viewModel.products, isEmpty);
      expect(viewModel.status.type, StatusType.loading);

      freshHome.complete(Result.failure('Refresh failed'));
      freshSearch.complete(Result.failure('Search failed'));
      await refresh;
      expect(viewModel.products, isEmpty);
      expect(viewModel.searchProducts, isEmpty);
      expect(viewModel.status.type, StatusType.failure);
      expect(viewModel.searchStatus.type, StatusType.failure);
    });

    test('profile removes stale cards and rejects an old in-flight page after save', () async {
      final stale = Completer<Result<ProfileListingsPage>>();
      final fresh = Completer<Result<ProfileListingsPage>>();
      final repository = _ListingsRepository()
        ..responses.addAll([
          Future.value(Result.success(_listingsPage('Old coat', hasMore: true))),
          stale.future,
          fresh.future,
        ]);
      final viewModel = ProfileListingsViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.loadInitialListings();
      final oldRequest = viewModel.loadMoreListings();
      final refresh = viewModel.refreshAfterListingEdit();
      expect(viewModel.listings, isEmpty);
      expect(viewModel.hasMore, isFalse);
      expect(viewModel.isLoadingMore, isFalse);

      fresh.complete(Result.success(_listingsPage('Updated coat')));
      await refresh;
      stale.complete(Result.success(_listingsPage('Old coat', hasMore: true)));
      await oldRequest;
      expect(viewModel.listings.single.name, 'Updated coat');
      expect(viewModel.hasMore, isFalse);
    });

    test('profile refresh supersedes first-page loading and fails without stale cards', () async {
      final stale = Completer<Result<ProfileListingsPage>>();
      final fresh = Completer<Result<ProfileListingsPage>>();
      final repository = _ListingsRepository()..responses.addAll([stale.future, fresh.future]);
      final viewModel = ProfileListingsViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      final oldRequest = viewModel.loadInitialListings();
      final refresh = viewModel.refreshAfterListingEdit();

      stale.complete(Result.success(_listingsPage('Old coat')));
      await oldRequest;
      expect(viewModel.listings, isEmpty);
      expect(viewModel.status.type, StatusType.loading);
      fresh.complete(Result.failure('Refresh failed'));
      await refresh;
      expect(viewModel.listings, isEmpty);
      expect(viewModel.status.type, StatusType.failure);
    });
  });

  group('Confirmed listing revisions', () {
    late _ProductRepository repository;
    late ProductViewModel productViewModel;

    setUp(() {
      repository = _ProductRepository();
      productViewModel = ProductViewModel(productRepository: repository, navigator: NavigationProvider());
    });
    tearDown(() => productViewModel.dispose());

    test('saved data replaces selected product and liked cache without changing likes membership', () {
      final original = _product(name: 'Old coat', version: 1);
      final saved = _product(name: 'Updated coat', version: 2);
      productViewModel.setProduct(original);
      productViewModel.cacheLikedProducts([original]);
      productViewModel.applyListingUpdate(saved);

      expect(productViewModel.product, same(saved));
      expect(productViewModel.cachedLikedProducts, [saved]);
      expect(productViewModel.isProductLiked(saved.id), isTrue);

      productViewModel.cacheLikedProducts([original]);
      productViewModel.setProduct(original);
      expect(productViewModel.product, same(saved));
      expect(productViewModel.cachedLikedProducts, [saved]);

      final other = _product(id: 'other', name: 'Other coat', version: 1);
      productViewModel.applyListingUpdate(other);
      expect(productViewModel.product, same(saved));
      expect(productViewModel.isProductLiked(other.id), isFalse);
    });

    test('newer backend revision wins and cannot be replaced by an older response', () {
      final saved = _product(name: 'Saved coat', version: 2);
      final newer = _product(name: 'Newer coat', version: 3);
      final unversioned = _product(name: 'Old unversioned coat');
      productViewModel.setProduct(saved);
      productViewModel.applyListingUpdate(saved);

      expect(productViewModel.resolveListing(newer), same(newer));
      expect(productViewModel.resolveListing(saved), same(newer));
      expect(productViewModel.resolveListing(unversioned), same(newer));
      productViewModel.applyListingUpdate(saved);
      expect(productViewModel.product, same(newer));
    });

    test('account reset clears confirmed revision overrides', () {
      final original = _product(name: 'Old coat', version: 1);
      final saved = _product(name: 'Updated coat', version: 2);
      productViewModel.applyListingUpdate(saved);
      productViewModel.clearUserState();
      expect(productViewModel.resolveListing(original), same(original));
    });

    test('legacy listings can refresh repeatedly without a version token', () {
      final first = _product(name: 'First details');
      final latest = _product(name: 'Latest details');
      productViewModel.applyListingUpdate(first);
      expect(productViewModel.resolveListing(latest), same(latest));
    });

    test('open liked view receives saved details without reliking items', () async {
      final original = _product(name: 'Old coat', version: 1);
      final saved = _product(name: 'Updated coat', version: 2);
      repository.responses.add(Future.value(Result.success([original])));
      final viewModel = LikedItemsViewModel(productRepository: repository, productViewModel: productViewModel);
      addTearDown(viewModel.dispose);
      await viewModel.loadLikedProducts();
      productViewModel.applyListingUpdate(saved);
      expect(viewModel.products, [saved]);
      expect(viewModel.status, LikedItemsStatus.loaded);
    });

    test('pre-edit liked response cannot overwrite confirmed details', () async {
      final original = _product(name: 'Old coat', version: 1);
      final saved = _product(name: 'Updated coat', version: 2);
      final response = Completer<Result<List<Product>>>();
      repository.responses.add(response.future);
      final viewModel = LikedItemsViewModel(productRepository: repository, productViewModel: productViewModel);
      addTearDown(viewModel.dispose);
      final loading = viewModel.loadLikedProducts();
      productViewModel.applyListingUpdate(saved);
      response.complete(Result.success([original]));
      await loading;
      expect(viewModel.products, [saved]);
      expect(productViewModel.cachedLikedProducts, [saved]);
    });

    test('later liked response displays a newer backend edit', () async {
      final saved = _product(name: 'Updated coat', version: 2);
      final newer = _product(name: 'Newer coat', version: 3);
      productViewModel.applyListingUpdate(saved);
      repository.responses.add(Future.value(Result.success([newer])));
      final viewModel = LikedItemsViewModel(productRepository: repository, productViewModel: productViewModel);
      addTearDown(viewModel.dispose);
      await viewModel.loadLikedProducts();
      expect(viewModel.products, [newer]);
      expect(productViewModel.resolveListing(saved), same(newer));
    });

    test('product navigation includes its ID for an authoritative detail fetch', () {
      final navigator = _NavigationProvider();
      final viewModel = ProductViewModel(productRepository: repository, navigator: navigator);
      addTearDown(viewModel.dispose);
      viewModel.goToProductPage(_product(name: 'Coat'));
      expect(navigator.route, AppRoutes.product);
      expect(navigator.arguments, {'productId': 'listing'});
    });
  });
}

Product _product({String id = 'listing', required String name, int? version}) => Product(
  id: id,
  userId: 'seller',
  name: name,
  description: 'A warm coat',
  quality: 'GOOD',
  productImages: const [],
  donation: 7,
  price: 7,
  securityFee: 1,
  likes: 0,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
  editVersion: version,
);

ProductPage _homePage(Product product, {bool hasMore = false}) => ProductPage(
  products: [product],
  limit: 20,
  nextCursor: hasMore ? 'next' : null,
  hasMore: hasMore,
);

ProfileListingsPage _listingsPage(String name, {bool hasMore = false}) => ProfileListingsPage(
  listings: [SellerListing(id: 'listing', name: name, imageUrls: const [], price: 7)],
  limit: 20,
  nextCursor: hasMore ? 'next' : null,
  hasMore: hasMore,
);
