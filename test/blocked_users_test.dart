import 'dart:async';

import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_view_model.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/home/home_repository.dart' as home;
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/home_screen.dart';
import 'package:cherry_mvp/features/liked_items/liked_items_view_model.dart';
import 'package:cherry_mvp/features/products/blocked_users.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/safety_repository.dart';
import 'package:cherry_mvp/features/profile/public_user_profile.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/public_profile_fixtures.dart';
import 'support/unexpected_api_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {
  _MockUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;
}

class _CheckoutRepositoryStub implements ICheckoutRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DonationRepositoryStub implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QueueHomeRepository implements home.IHomeRepository {
  _QueueHomeRepository(this._handler);

  final Future<Result<home.ProductPage>> Function({
    int limit,
    String? cursor,
    String? search,
    String? categoryId,
  })
  _handler;
  final calls = <({String? cursor, String? search, String? categoryId})>[];

  @override
  Future<Result<home.ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
    String? categoryId,
  }) {
    calls.add((cursor: cursor, search: search, categoryId: categoryId));
    return _handler(
      limit: limit,
      cursor: cursor,
      search: search,
      categoryId: categoryId,
    );
  }
}

class _FakeApiService implements ApiService {
  _FakeApiService({this.getHandler, this.postHandler});

  final Future<Result<dynamic>> Function(String endpoint, Map<String, dynamic>? queryParameters)? getHandler;
  final Future<Result<dynamic>> Function(String endpoint, dynamic data)? postHandler;
  final getCalls = <String>[];
  final postCalls = <String>[];

  @override
  Future<Result<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    getCalls.add(endpoint);
    if (getHandler == null) return Result.failure('Unexpected GET $endpoint');
    final result = await getHandler!(endpoint, queryParameters);
    if (!result.isSuccess) {
      return Result.failure(result.error, statusCode: result.statusCode);
    }
    return Result.success(result.value as T, statusCode: result.statusCode);
  }

  @override
  Future<Result<T>> post<T>(String endpoint, {dynamic data}) async {
    postCalls.add(endpoint);
    if (postHandler == null) return Result.success(const {'success': true} as T);
    final result = await postHandler!(endpoint, data);
    if (!result.isSuccess) {
      return Result.failure(result.error, statusCode: result.statusCode);
    }
    return Result.success(result.value as T, statusCode: result.statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubProductRepository extends ProductRepository {
  _StubProductRepository({
    super.blockedUsers,
    this.likedProducts = const [],
    this.likeHandler,
  }) : super(const UnexpectedApiService());

  final List<Product> likedProducts;
  final Future<Result<ProductLikeUpdate>> Function(Product product)? likeHandler;

  @override
  Future<Result<List<Product>>> fetchLikedProducts() async {
    return Result.success(likedProducts);
  }

  @override
  Future<Result<ProductLikeUpdate>> likeProduct(Product product) async {
    if (likeHandler != null) return likeHandler!(product);
    return Result.success(const ProductLikeUpdate(liked: true, likes: 2));
  }
}

class _StubCharityProfileRepository implements ICharityProfileRepository {
  _StubCharityProfileRepository(this._pages, {this.fetchHandler});

  final Charity _charity = Charity(
    id: 'charity-1',
    name: 'Test Charity',
    imageUrl: '',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final Map<String?, List<Product>> _pages;
  final Future<Result<CharityProfilePageData>> Function(Charity charity, String? cursor)? fetchHandler;
  final Map<String?, String?> _cursors = {null: 'page-2', 'page-2': null};
  final calls = <String?>[];

  @override
  Future<Result<Charity>> fetchCharity({String? charityId, String? charityName}) async {
    return Result.success(_charity);
  }

  @override
  Future<Result<CharityProfilePageData>> fetchProducts(
    Charity charity, {
    int limit = 20,
    String? cursor,
  }) async {
    calls.add(cursor);
    if (fetchHandler != null) {
      return fetchHandler!(charity, cursor);
    }
    final nextCursor = _cursors[cursor];
    return Result.success(
      CharityProfilePageData(
        charity: _charity,
        products: _pages[cursor] ?? const [],
        nextCursor: nextCursor,
        hasMore: nextCursor != null,
      ),
    );
  }
}

Product _product({
  required String id,
  required String userId,
  String name = 'Item',
  String charityId = 'charity-1',
}) => Product(
  id: id,
  userId: userId,
  name: name,
  description: '$name description',
  quality: 'Good',
  productImages: const [AppImages.product1],
  donation: 10,
  price: 15,
  securityFee: 1.5,
  likes: 1,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
  charityId: charityId,
);

void main() {
  group('BlockedUsers store', () {
    test('hydrates once, shares concurrent calls, and ignores stale responses after account change', () async {
      var currentUserId = 'viewer-a';
      final firstFetch = Completer<Result<Set<String>>>();
      final secondFetch = Completer<Result<Set<String>>>();
      var fetchCalls = 0;

      final blockedUsers = BlockedUsers(
        currentUserIdProvider: () => currentUserId,
        fetchBlockedUsers: () {
          fetchCalls++;
          return fetchCalls == 1 ? firstFetch.future : secondFetch.future;
        },
      );
      addTearDown(blockedUsers.dispose);

      final pendingA1 = blockedUsers.ensureHydrated();
      final pendingA2 = blockedUsers.ensureHydrated();
      expect(identical(pendingA1, pendingA2), isTrue);
      expect(fetchCalls, 1);

      currentUserId = 'viewer-b';
      blockedUsers.clear();
      final pendingB = blockedUsers.ensureHydrated();
      expect(fetchCalls, 2);

      firstFetch.complete(Result.success({'seller-a'}));
      await pendingA1;
      expect(blockedUsers.contains('seller-a'), isFalse);

      secondFetch.complete(Result.success({'seller-b'}));
      await pendingB;
      expect(blockedUsers.contains('seller-b'), isTrue);
      expect(blockedUsers.isHydrated, isTrue);

      await blockedUsers.ensureHydrated();
      expect(fetchCalls, 2);
    });

    test('preserves a block added locally while a forceRefresh hydration is in flight', () async {
      final refreshFetch = Completer<Result<Set<String>>>();
      final blockedUsers = BlockedUsers(
        fetchBlockedUsers: () => refreshFetch.future,
      )..add('previously-blocked');
      addTearDown(blockedUsers.dispose);

      final refreshing = blockedUsers.ensureHydrated(forceRefresh: true);
      blockedUsers.add('newly-blocked');

      // Server snapshot predates the new local block and reflects an unblock of previously-blocked.
      refreshFetch.complete(Result.success({'server-blocked'}));
      await refreshing;

      expect(blockedUsers.contains('server-blocked'), isTrue);
      expect(blockedUsers.contains('newly-blocked'), isTrue);
      expect(blockedUsers.contains('previously-blocked'), isFalse);
    });

    test('retains locally recorded blocks if hydration fails and allows later retry', () async {
      var shouldFail = true;
      final blockedUsers = BlockedUsers(
        fetchBlockedUsers: () async => shouldFail ? Result.failure('offline') : Result.success({'server-seller'}),
      )..add('local-seller');
      addTearDown(blockedUsers.dispose);

      await blockedUsers.ensureHydrated();
      expect(blockedUsers.isHydrated, isFalse);
      expect(blockedUsers.contains('local-seller'), isTrue);

      shouldFail = false;
      await blockedUsers.ensureHydrated();
      expect(blockedUsers.isHydrated, isTrue);
      expect(blockedUsers.contains('local-seller'), isTrue);
      expect(blockedUsers.contains('server-seller'), isTrue);
    });
  });

  group('ViewModels and repositories filtering blocked sellers', () {
    test('HomeViewModel hydrates blocked users, filters Home & Search, and auto-advances empty pages', () async {
      final blockedUsers = BlockedUsers(
        fetchBlockedUsers: () async => Result.success({'blocked-seller'}),
      );
      addTearDown(blockedUsers.dispose);

      final blockedItem = _product(id: 'p-blocked', userId: 'blocked-seller', name: 'Blocked boots');
      final openItem = _product(id: 'p-open', userId: 'open-seller', name: 'Peanut shirt');
      final secondBlockedItem = _product(id: 'p-second', userId: 'seller-2', name: 'Second seller shirt');

      final homeRepo = _QueueHomeRepository(({limit = 20, cursor, search, categoryId}) async {
        if (cursor == null) {
          return Result.success(
            home.ProductPage(
              products: [blockedItem],
              limit: limit,
              nextCursor: 'page-2',
              hasMore: true,
            ),
          );
        }
        return Result.success(
          home.ProductPage(
            products: [openItem, secondBlockedItem],
            limit: limit,
            nextCursor: null,
            hasMore: false,
          ),
        );
      });

      final homeModel = HomeViewModel(
        homeRepository: homeRepo,
        blockedUsers: blockedUsers,
      );
      addTearDown(homeModel.dispose);

      await homeModel.fetchProducts();
      expect(homeRepo.calls.map((c) => c.cursor), [null, 'page-2']);
      expect(homeModel.products.map((p) => p.id), ['p-open', 'p-second']);
      expect(homeModel.status.type, StatusType.success);

      await homeModel.submitSearch('shirt');
      expect(homeModel.searchProducts.map((p) => p.id), ['p-open', 'p-second']);

      // Blocking seller-2 immediately removes their items from both Home and Search.
      blockedUsers.add('seller-2');
      expect(homeModel.products.map((p) => p.id), ['p-open']);
      expect(homeModel.searchProducts.map((p) => p.id), ['p-open']);

      // Account change clears cached feed so a new account reloads cleanly.
      homeModel.clearForAccountChange();
      expect(homeModel.products, isEmpty);
      expect(homeModel.status.type, StatusType.uninitialized);
    });

    test('ProductViewModel.blockSeller records block and removes selected product and cached likes', () async {
      final blockedUsers = BlockedUsers();
      addTearDown(blockedUsers.dispose);

      final api = _FakeApiService();
      final blockedProduct = _product(id: 'p-1', userId: 'seller-1', name: 'Boots');
      final otherProduct = _product(id: 'p-2', userId: 'seller-2', name: 'Shirt');
      final productRepo = _StubProductRepository(
        blockedUsers: blockedUsers,
        likedProducts: [blockedProduct, otherProduct],
      );
      final productModel = ProductViewModel(
        productRepository: productRepo,
        safetyRepository: SafetyRepository(api),
        navigator: NavigationProvider(),
        blockedUsers: blockedUsers,
        currentUserIdProvider: () => 'viewer-1',
      );
      final likedModel = LikedItemsViewModel(
        productRepository: productRepo,
        productViewModel: productModel,
        blockedUsers: blockedUsers,
      );
      addTearDown(productModel.dispose);
      addTearDown(likedModel.dispose);

      productModel.setProduct(blockedProduct);
      await likedModel.loadLikedProducts();
      expect(likedModel.products.map((p) => p.id), ['p-1', 'p-2']);

      final result = await productModel.blockSeller('seller-1');
      expect(result.isSuccess, isTrue);
      expect(api.postCalls, [ApiEndpoints.blockUser('seller-1')]);
      expect(blockedUsers.contains('seller-1'), isTrue);
      expect(productModel.product, isNull);
      expect(productModel.cachedLikedProducts.map((p) => p.id), ['p-2']);
      expect(likedModel.products.map((p) => p.id), ['p-2']);

      // Blocked seller's product cannot be re-selected.
      productModel.setProduct(blockedProduct);
      expect(productModel.product, isNull);
    });

    test('ProductRepository and PublicUserProfileRepository reject blocked seller data', () async {
      final blockedUsers = BlockedUsers(
        fetchBlockedUsers: () async => Result.success({'blocked-seller'}),
      );
      addTearDown(blockedUsers.dispose);

      final api = _FakeApiService(
        getHandler: (endpoint, _) async {
          if (endpoint == ApiEndpoints.productWithDetailsById('p-blocked')) {
            return Result.success({
              'success': true,
              'data': {
                'id': 'p-blocked',
                'userId': 'blocked-seller',
                'name': 'Boots',
                'description': 'Worn',
                'quality': 'Good',
                'product_images': [AppImages.product1],
                'donation': 10,
                'price': 15,
                'likes': 0,
                'number': 1,
                'size': 'M',
                'postageSize': 'small',
              },
            });
          }
          return Result.success({
            'success': true,
            'data': {'id': 'blocked-seller', 'username': 'BradVe', 'profileImageUrl': null},
          });
        },
      );

      final productRepo = ProductRepository(api, blockedUsers: blockedUsers);
      final profileRepo = PublicUserProfileRepository(api, blockedUsers: blockedUsers);

      final productResult = await productRepo.fetchProduct('p-blocked');
      expect(productResult.isSuccess, isFalse);
      expect(productResult.statusCode, 404);

      final userResult = await profileRepo.fetchUser('blocked-seller');
      expect(userResult.isSuccess, isFalse);
      expect(userResult.statusCode, 404);
      expect(api.getCalls, isNot(contains(ApiEndpoints.publicUserProfile('blocked-seller'))));
    });

    test('CharityProfileViewModel auto-advances past blocked seller pages and reacts to new blocks', () async {
      final blockedUsers = BlockedUsers(
        fetchBlockedUsers: () async => Result.success({'blocked-seller'}),
      );
      addTearDown(blockedUsers.dispose);

      final repo = _StubCharityProfileRepository({
        null: [_product(id: 'p-1', userId: 'blocked-seller')],
        'page-2': [
          _product(id: 'p-2', userId: 'seller-2'),
          _product(id: 'p-3', userId: 'seller-3'),
        ],
      });
      final viewModel = CharityProfileViewModel(
        args: const CharityProfileArgs(charityId: 'charity-1'),
        repository: repo,
        blockedUsers: blockedUsers,
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();
      expect(repo.calls, [null, 'page-2']);
      expect(viewModel.products.map((p) => p.id), ['p-2', 'p-3']);

      blockedUsers.add('seller-2');
      expect(viewModel.products.map((p) => p.id), ['p-3']);
    });

    test('PublicUserProfileViewModel marks blocked user unavailable immediately without fetching', () async {
      final blockedUsers = BlockedUsers(
        fetchBlockedUsers: () async => Result.success({'brad-ve'}),
      );
      addTearDown(blockedUsers.dispose);

      final repo = FakePublicProfileRepository((userId, _) => Result.success(publicProfilePage(userId: userId)));
      final viewModel = PublicUserProfileViewModel(
        userId: 'brad-ve',
        repository: repo,
        blockedUsers: blockedUsers,
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadProfile();
      expect(viewModel.status, PublicProfileStatus.unavailable);
      expect(viewModel.user, isNull);
      expect(repo.calls, isEmpty);
    });

    test(
      'HomeViewModel reports continuation failures during blocked auto-advance, retains cursor, and normalizes missing cursors',
      () async {
        final blockedUsers = BlockedUsers(
          fetchBlockedUsers: () async => Result.success({'blocked-seller'}),
        );
        addTearDown(blockedUsers.dispose);

        final blockedItem = _product(id: 'p-blocked', userId: 'blocked-seller', name: 'Blocked boots');
        final openItem = _product(id: 'p-open', userId: 'open-seller', name: 'Open coat');
        var failPage2 = true;

        final homeRepo = _QueueHomeRepository(({limit = 20, cursor, search, categoryId}) async {
          if (search == 'missing-cursor') {
            return Result.success(
              home.ProductPage(
                products: const [],
                limit: limit,
                nextCursor: null,
                hasMore: true,
              ),
            );
          }
          if (cursor == null) {
            return Result.success(
              home.ProductPage(
                products: [blockedItem],
                limit: limit,
                nextCursor: 'page-2',
                hasMore: true,
              ),
            );
          }
          if (failPage2) {
            return Result.failure('offline');
          }
          return Result.success(
            home.ProductPage(
              products: [openItem],
              limit: limit,
              nextCursor: null,
              hasMore: false,
            ),
          );
        });

        final homeModel = HomeViewModel(
          homeRepository: homeRepo,
          blockedUsers: blockedUsers,
        );
        addTearDown(homeModel.dispose);

        // Home auto-advance continuation failure exposes retryable error and retains cursor.
        await homeModel.fetchProducts();
        expect(homeModel.products, isEmpty);
        expect(homeModel.hasMore, isTrue);
        expect(homeModel.nextCursor, 'page-2');
        expect(homeModel.homeLoadMoreError, isNotEmpty);

        // Explicit retry bypasses backoff and resumes from the failed cursor.
        failPage2 = false;
        await homeModel.loadMoreProducts(ignoreBackoff: true);
        expect(homeModel.products.map((p) => p.id), ['p-open']);
        expect(homeModel.homeLoadMoreError, isNull);
        expect(homeModel.hasMore, isFalse);

        // Search auto-advance continuation failure exposes searchLoadMoreError and retries from failed cursor.
        failPage2 = true;
        await homeModel.submitSearch('coat');
        expect(homeModel.searchProducts, isEmpty);
        expect(homeModel.searchHasMore, isTrue);
        expect(homeModel.isSearchEmpty, isFalse);
        expect(homeModel.searchNextCursor, 'page-2');
        expect(homeModel.searchLoadMoreError, isNotEmpty);

        failPage2 = false;
        await homeModel.loadMoreSearchProducts();
        expect(homeModel.searchProducts.map((p) => p.id), ['p-open']);
        expect(homeModel.searchLoadMoreError, isNull);
        expect(homeModel.searchHasMore, isFalse);

        // First-page pagination normalizes hasMore=true with null cursor to hasMore=false.
        await homeModel.submitSearch('missing-cursor');
        expect(homeModel.searchHasMore, isFalse);
        expect(homeModel.searchNextCursor, isNull);
        expect(homeModel.isSearchEmpty, isTrue);
      },
    );

    test(
      'ProductRepository fails closed with retryable failure when block hydration fails and succeeds on retry',
      () async {
        var shouldFailBlocks = true;
        final blockedUsers = BlockedUsers(
          currentUserIdProvider: () => 'viewer-1',
          fetchBlockedUsers: () async =>
              shouldFailBlocks ? Result.failure('offline') : Result.success({'blocked-seller'}),
        );
        addTearDown(blockedUsers.dispose);

        final api = _FakeApiService(
          getHandler: (endpoint, _) async {
            if (endpoint == ApiEndpoints.productWithDetailsById('p-blocked')) {
              return Result.success({
                'success': true,
                'data': {
                  'id': 'p-blocked',
                  'userId': 'blocked-seller',
                  'name': 'Boots',
                  'description': 'Worn',
                  'quality': 'Good',
                  'product_images': [AppImages.product1],
                  'donation': 10,
                  'price': 15,
                  'likes': 0,
                  'number': 1,
                  'size': 'M',
                  'postageSize': 'small',
                },
              });
            }
            if (endpoint == ApiEndpoints.likedProducts) {
              return Result.success({
                'success': true,
                'data': {
                  'products': [
                    {
                      'id': 'p-blocked',
                      'userId': 'blocked-seller',
                      'name': 'Boots',
                      'description': 'Worn',
                      'quality': 'Good',
                      'product_images': [AppImages.product1],
                      'donation': 10,
                      'price': 15,
                      'likes': 1,
                      'number': 1,
                      'size': 'M',
                      'postageSize': 'small',
                    },
                    {
                      'id': 'p-open',
                      'userId': 'open-seller',
                      'name': 'Shirt',
                      'description': 'Clean',
                      'quality': 'Good',
                      'product_images': [AppImages.product1],
                      'donation': 10,
                      'price': 15,
                      'likes': 1,
                      'number': 1,
                      'size': 'M',
                      'postageSize': 'small',
                    },
                  ],
                },
              });
            }
            return Result.failure('Unexpected GET $endpoint');
          },
        );

        final productRepo = ProductRepository(api, blockedUsers: blockedUsers);

        final failedProduct = await productRepo.fetchProduct('p-blocked');
        expect(failedProduct.isSuccess, isFalse);
        expect(failedProduct.errorCode, isNot('LISTING_NOT_FOUND'));
        expect(failedProduct.statusCode, isNot(404));

        final failedLiked = await productRepo.fetchLikedProducts();
        expect(failedLiked.isSuccess, isFalse);

        // Once block hydration succeeds, blocked listing is hidden and liked items are filtered.
        shouldFailBlocks = false;
        final blockedResult = await productRepo.fetchProduct('p-blocked');
        expect(blockedResult.isSuccess, isFalse);
        expect(blockedResult.errorCode, 'LISTING_NOT_FOUND');
        expect(blockedResult.statusCode, 404);

        final likedResult = await productRepo.fetchLikedProducts();
        expect(likedResult.isSuccess, isTrue);
        expect(likedResult.value!.map((p) => p.id), ['p-open']);
      },
    );

    test('ProductViewModel stale account like response does not clear new account pending state', () async {
      var currentUserId = 'viewer-a';
      final likeA = Completer<Result<ProductLikeUpdate>>();
      final likeB = Completer<Result<ProductLikeUpdate>>();
      var likeCalls = 0;

      final product = _product(id: 'p-1', userId: 'seller-1', name: 'Jacket');
      final repo = _StubProductRepository(
        likeHandler: (_) {
          likeCalls++;
          return likeCalls == 1 ? likeA.future : likeB.future;
        },
      );
      final viewModel = ProductViewModel(
        productRepository: repo,
        navigator: NavigationProvider(),
        currentUserIdProvider: () => currentUserId,
      );
      addTearDown(viewModel.dispose);

      final pendingA = viewModel.setProductLiked(product, true);
      expect(viewModel.isLikeUpdatePending('p-1'), isTrue);

      // Switch to account B and start a like update for the same product.
      currentUserId = 'viewer-b';
      final pendingB = viewModel.setProductLiked(product, true);
      expect(viewModel.isLikeUpdatePending('p-1'), isTrue);

      // Stale completion from account A must not clear account B's pending marker.
      likeA.complete(Result.success(const ProductLikeUpdate(liked: true, likes: 2)));
      await pendingA;
      expect(viewModel.isLikeUpdatePending('p-1'), isTrue);

      likeB.complete(Result.success(const ProductLikeUpdate(liked: true, likes: 2)));
      final resultB = await pendingB;
      expect(resultB.isSuccess, isTrue);
      expect(viewModel.isLikeUpdatePending('p-1'), isFalse);
      expect(viewModel.isProductLiked('p-1'), isTrue);
    });

    test('PublicUserProfileRepository.fetchProfile hydrates blocked users only once when hydration fails', () async {
      var hydrationCalls = 0;
      final blockedUsers = BlockedUsers(
        currentUserIdProvider: () => 'viewer-1',
        fetchBlockedUsers: () async {
          hydrationCalls++;
          return Result.failure('offline');
        },
      );
      addTearDown(blockedUsers.dispose);

      final api = _FakeApiService();
      final repo = PublicUserProfileRepository(api, blockedUsers: blockedUsers);

      final result = await repo.fetchProfile('seller-1');
      expect(result.isSuccess, isFalse);
      expect(result.statusCode, isNot(404));
      expect(hydrationCalls, 1);
      expect(api.getCalls, isEmpty);
    });

    test('CharityProfileViewModel does not restore a seller blocked while loadMore is in flight', () async {
      final blockedUsers = BlockedUsers();
      addTearDown(blockedUsers.dispose);

      final itemA = _product(id: 'p-a', userId: 'seller-a', name: 'Blocked mid-load');
      final itemB = _product(id: 'p-b', userId: 'seller-b', name: 'Kept item');
      final itemC = _product(id: 'p-c', userId: 'seller-c', name: 'Page 2 item');
      final page2Completer = Completer<Result<CharityProfilePageData>>();

      late final _StubCharityProfileRepository repo;
      repo = _StubCharityProfileRepository(
        const {},
        fetchHandler: (charity, cursor) async {
          if (cursor == null) {
            return Result.success(
              CharityProfilePageData(
                charity: charity,
                products: [itemA, itemB],
                nextCursor: 'page-2',
                hasMore: true,
              ),
            );
          }
          return page2Completer.future;
        },
      );

      final viewModel = CharityProfileViewModel(
        args: const CharityProfileArgs(charityId: 'charity-1'),
        repository: repo,
        blockedUsers: blockedUsers,
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();
      expect(viewModel.products.map((p) => p.id), ['p-a', 'p-b']);

      final loadMoreFuture = viewModel.loadMore();
      blockedUsers.add('seller-a');
      expect(viewModel.products.map((p) => p.id), ['p-b']);

      page2Completer.complete(
        Result.success(
          CharityProfilePageData(
            charity: viewModel.charity!,
            products: [itemC],
            nextCursor: null,
            hasMore: false,
          ),
        ),
      );
      await loadMoreFuture;

      expect(viewModel.products.map((p) => p.id), ['p-b', 'p-c']);
    });
  });

  group('End-to-end widget blocking flows', () {
    Future<
      ({
        NavigationProvider navigator,
        BlockedUsers blockedUsers,
        HomeViewModel homeViewModel,
        _FakeApiService api,
      })
    >
    pumpApp(
      WidgetTester tester, {
      required List<Product> serverProducts,
      Set<String> initialServerBlocks = const {},
    }) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1000, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final serverBlocks = Set<String>.from(initialServerBlocks);
      final api = _FakeApiService(
        getHandler: (endpoint, _) async {
          if (endpoint == ApiEndpoints.blocks) {
            return Result.success({
              'success': true,
              'data': {
                'blocks': [
                  for (final id in serverBlocks) {'id': 'block-$id', 'blockerId': 'viewer-1', 'blockedUserId': id},
                ],
              },
            });
          }
          return Result.failure('Unexpected GET $endpoint');
        },
        postHandler: (endpoint, _) async {
          if (endpoint.startsWith('${ApiEndpoints.blocks}/')) {
            final sellerId = Uri.decodeComponent(endpoint.substring('${ApiEndpoints.blocks}/'.length));
            serverBlocks.add(sellerId);
          }
          return Result.success(const {'success': true});
        },
      );

      final safetyRepo = SafetyRepository(api);
      final auth = _MockFirebaseAuth();
      when(auth.currentUser).thenReturn(_MockUser('viewer-1'));

      final blockedUsers = BlockedUsers(
        fetchBlockedUsers: safetyRepo.fetchBlockedUsers,
        currentUserIdProvider: () => auth.currentUser?.uid,
      );
      final navigator = NavigationProvider();
      final productRepo = _StubProductRepository(blockedUsers: blockedUsers);
      final productViewModel = ProductViewModel(
        productRepository: productRepo,
        safetyRepository: safetyRepo,
        navigator: navigator,
        blockedUsers: blockedUsers,
        currentUserIdProvider: () => auth.currentUser?.uid,
      );
      final homeRepo = _QueueHomeRepository(({limit = 20, cursor, search, categoryId}) async {
        // Simulates current backend: still returns blocked sellers' listings in /api/products/with-details.
        return Result.success(
          home.ProductPage(
            products: serverProducts,
            limit: limit,
            nextCursor: null,
            hasMore: false,
          ),
        );
      });
      final homeViewModel = HomeViewModel(
        homeRepository: homeRepo,
        blockedUsers: blockedUsers,
      );
      final checkoutViewModel = CheckoutViewModel(
        donationRepository: _DonationRepositoryStub(),
        checkoutRepository: _CheckoutRepositoryStub(),
        navigator: navigator,
        currentUserIdProvider: () => auth.currentUser?.uid,
      );
      final publicProfileRepo = FakePublicProfileRepository((userId, _) {
        if (blockedUsers.contains(userId)) {
          return Result.failure('This profile is unavailable.', statusCode: 404);
        }
        return Result.success(
          publicProfilePage(
            userId: userId,
            username: userId == 'brad-ve' ? 'BradVe' : 'OtherSeller',
            products: serverProducts.where((p) => p.userId == userId).toList(),
          ),
        );
      });

      addTearDown(blockedUsers.dispose);
      addTearDown(productViewModel.dispose);
      addTearDown(homeViewModel.dispose);
      addTearDown(checkoutViewModel.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FirebaseAuth>.value(value: auth),
            Provider<NavigationProvider>.value(value: navigator),
            Provider<IPublicUserProfileRepository>.value(value: publicProfileRepo),
            ChangeNotifierProvider<BlockedUsers>.value(value: blockedUsers),
            ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
            ChangeNotifierProvider<HomeViewModel>.value(value: homeViewModel),
            ChangeNotifierProvider<CheckoutViewModel>.value(value: checkoutViewModel),
          ],
          child: MaterialApp(
            navigatorKey: navigator.navigatorKey,
            onGenerateRoute: AppRoutes.generateRoute,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return (
        navigator: navigator,
        blockedUsers: blockedUsers,
        homeViewModel: homeViewModel,
        api: api,
      );
    }

    testWidgets(
      'blocking a seller from their public profile pops back to Home, hides their items immediately, and stays hidden on refresh',
      (tester) async {
        final bradBoots = _product(id: 'boots-1', userId: 'brad-ve', name: 'North Face Hedgehog');
        final peanutShirt = _product(id: 'shirt-1', userId: 'other-seller', name: 'Peanut shirt');

        final app = await pumpApp(
          tester,
          serverProducts: [bradBoots, peanutShirt],
        );

        expect(find.text('North Face Hedgehog'), findsOneWidget);
        expect(find.text('Peanut shirt'), findsOneWidget);

        // Open BradVe's product, then open BradVe's profile.
        await tester.tap(find.text('North Face Hedgehog'));
        await tester.pumpAndSettle();
        expect(find.byType(ProductPage), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('seller-public-profile')));
        await tester.pumpAndSettle();
        expect(find.byType(PublicUserProfile), findsOneWidget);
        expect(find.text('BradVe'), findsOneWidget);

        // Open 3-dot menu and block BradVe.
        await tester.tap(find.byTooltip(AppStrings.productPageMoreActions));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.productPageBlockSeller));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, AppStrings.productPageBlockSellerConfirm));
        await tester.pumpAndSettle();

        // Both PublicUserProfile and ProductPage for BradVe were popped back to Home.
        expect(find.byType(PublicUserProfile), findsNothing);
        expect(find.byType(ProductPage), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text(AppStrings.productPageBlockSellerSuccess), findsOneWidget);
        expect(app.api.postCalls, [ApiEndpoints.blockUser('brad-ve')]);

        // BradVe's listing is gone from Home while other sellers remain.
        expect(find.text('North Face Hedgehog'), findsNothing);
        expect(find.text('Peanut shirt'), findsOneWidget);

        // Pulling to refresh still keeps BradVe's item hidden even though backend returns it.
        await app.homeViewModel.refreshProducts();
        await tester.pumpAndSettle();
        expect(find.text('North Face Hedgehog'), findsNothing);
        expect(find.text('Peanut shirt'), findsOneWidget);

        // Navigating to BradVe's profile shows unavailable and hides the safety menu.
        unawaited(app.navigator.openPublicUserProfile('brad-ve'));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.publicProfileUnavailable), findsOneWidget);
        expect(find.text('BradVe'), findsNothing);
        expect(find.byTooltip(AppStrings.productPageMoreActions), findsNothing);
      },
    );

    testWidgets(
      'blocking a seller directly from ProductPage pops back to Home and removes their listings',
      (tester) async {
        final bradBoots = _product(id: 'boots-1', userId: 'brad-ve', name: 'North Face Hedgehog');
        final peanutShirt = _product(id: 'shirt-1', userId: 'other-seller', name: 'Peanut shirt');

        final app = await pumpApp(
          tester,
          serverProducts: [bradBoots, peanutShirt],
        );

        await tester.tap(find.text('North Face Hedgehog'));
        await tester.pumpAndSettle();
        expect(find.byType(ProductPage), findsOneWidget);

        await tester.tap(find.byTooltip(AppStrings.productPageMoreActions));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.productPageBlockSeller));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, AppStrings.productPageBlockSellerConfirm));
        await tester.pumpAndSettle();

        expect(find.byType(ProductPage), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('North Face Hedgehog'), findsNothing);
        expect(find.text('Peanut shirt'), findsOneWidget);
        expect(app.blockedUsers.contains('brad-ve'), isTrue);
      },
    );

    testWidgets(
      'previously blocked sellers stay hidden on fresh app launch via GET /api/blocks',
      (tester) async {
        final bradBoots = _product(id: 'boots-1', userId: 'brad-ve', name: 'North Face Hedgehog');
        final peanutShirt = _product(id: 'shirt-1', userId: 'other-seller', name: 'Peanut shirt');

        final app = await pumpApp(
          tester,
          serverProducts: [bradBoots, peanutShirt],
          initialServerBlocks: const {'brad-ve'},
        );

        expect(app.api.getCalls, contains(ApiEndpoints.blocks));
        expect(find.text('North Face Hedgehog'), findsNothing);
        expect(find.text('Peanut shirt'), findsOneWidget);
      },
    );

    testWidgets(
      'DashboardPage offers Load more when auto-advance stops at the page cap and Retry on continuation failure',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(1000, 2200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final blockedUsers = BlockedUsers(
          fetchBlockedUsers: () async => Result.success({'blocked-seller'}),
        );
        final navigator = NavigationProvider();
        final auth = _MockFirebaseAuth();
        when(auth.currentUser).thenReturn(_MockUser('viewer-1'));
        final productRepo = _StubProductRepository(blockedUsers: blockedUsers);
        final productViewModel = ProductViewModel(
          productRepository: productRepo,
          navigator: navigator,
          blockedUsers: blockedUsers,
          currentUserIdProvider: () => 'viewer-1',
        );

        // 5 consecutive blocked pages (exhausting initial + maxAutoAdvanceEmptyPages=4),
        // followed by a 6th page that fails once and then returns a visible product.
        var failFinalPage = true;
        final homeRepo = _QueueHomeRepository(({limit = 20, cursor, search, categoryId}) async {
          final pageIndex = cursor == null ? 0 : int.parse(cursor.replaceFirst('p-', ''));
          if (pageIndex < HomeViewModel.maxAutoAdvanceEmptyPages + 1) {
            return Result.success(
              home.ProductPage(
                products: [_product(id: 'blocked-$pageIndex', userId: 'blocked-seller', name: 'Hidden $pageIndex')],
                limit: limit,
                nextCursor: 'p-${pageIndex + 1}',
                hasMore: true,
              ),
            );
          }
          if (failFinalPage) {
            return Result.failure('offline');
          }
          return Result.success(
            home.ProductPage(
              products: [_product(id: 'visible-final', userId: 'open-seller', name: 'Visible Jacket')],
              limit: limit,
              nextCursor: null,
              hasMore: false,
            ),
          );
        });
        final homeViewModel = HomeViewModel(
          homeRepository: homeRepo,
          blockedUsers: blockedUsers,
        );

        addTearDown(blockedUsers.dispose);
        addTearDown(productViewModel.dispose);
        addTearDown(homeViewModel.dispose);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<FirebaseAuth>.value(value: auth),
              Provider<NavigationProvider>.value(value: navigator),
              ChangeNotifierProvider<BlockedUsers>.value(value: blockedUsers),
              ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
              ChangeNotifierProvider<HomeViewModel>.value(value: homeViewModel),
            ],
            child: MaterialApp(
              navigatorKey: navigator.navigatorKey,
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Stopped at auto-advance cap with hasMore=true: must show Load more, not empty state.
        expect(find.text(AppStrings.noProductsAvailable), findsNothing);
        expect(find.text(AppStrings.profileListingsLoadMore), findsOneWidget);

        // Tap Load more when next page fails -> shows retryable error + Retry button.
        await tester.tap(find.text(AppStrings.profileListingsLoadMore));
        await tester.pumpAndSettle();
        expect(find.text('Could not load more items. Please try again.'), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);

        // Tap Retry immediately (ignoring backoff) -> loads visible listing.
        failFinalPage = false;
        await tester.tap(find.text(AppStrings.retry));
        await tester.pumpAndSettle();
        expect(find.text('Visible Jacket'), findsOneWidget);
      },
    );

    testWidgets(
      'ProductPage renders unavailable scaffold for blocked ID-only listing and ignores stale block after product change',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 2200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final blockedUsers = BlockedUsers(
          fetchBlockedUsers: () async => Result.success({'blocked-seller'}),
        );
        final blockCompleter = Completer<Result<dynamic>>();
        final api = _FakeApiService(
          getHandler: (endpoint, _) async {
            if (endpoint == ApiEndpoints.productWithDetailsById('p-blocked')) {
              return Result.success({
                'success': true,
                'data': {
                  'id': 'p-blocked',
                  'userId': 'blocked-seller',
                  'name': 'Blocked Boots',
                  'description': 'Worn',
                  'quality': 'Good',
                  'product_images': [AppImages.product1],
                  'donation': 10,
                  'price': 15,
                  'likes': 0,
                  'number': 1,
                  'size': 'M',
                  'postageSize': 'small',
                },
              });
            }
            return Result.failure('Unexpected GET $endpoint');
          },
          postHandler: (_, _) => blockCompleter.future,
        );
        final auth = _MockFirebaseAuth();
        when(auth.currentUser).thenReturn(_MockUser('viewer-1'));
        final navigator = NavigationProvider();
        final productRepo = ProductRepository(api, blockedUsers: blockedUsers);
        final productViewModel = ProductViewModel(
          productRepository: productRepo,
          safetyRepository: SafetyRepository(api),
          navigator: navigator,
          blockedUsers: blockedUsers,
          currentUserIdProvider: () => 'viewer-1',
        );
        final checkoutViewModel = CheckoutViewModel(
          donationRepository: _DonationRepositoryStub(),
          checkoutRepository: _CheckoutRepositoryStub(),
          navigator: navigator,
          currentUserIdProvider: () => 'viewer-1',
        );

        addTearDown(blockedUsers.dispose);
        addTearDown(productViewModel.dispose);
        addTearDown(checkoutViewModel.dispose);

        Widget wrap(Widget child) => MultiProvider(
          providers: [
            Provider<FirebaseAuth>.value(value: auth),
            Provider<NavigationProvider>.value(value: navigator),
            ChangeNotifierProvider<BlockedUsers>.value(value: blockedUsers),
            ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
            ChangeNotifierProvider<CheckoutViewModel>.value(value: checkoutViewModel),
          ],
          child: MaterialApp(
            navigatorKey: navigator.navigatorKey,
            home: child,
          ),
        );

        // 1. ID-only ProductPage for blocked seller renders unavailable scaffold, not Retry.
        await tester.pumpWidget(wrap(const ProductPage(productId: 'p-blocked')));
        await tester.pumpAndSettle();
        expect(find.text('This listing is no longer available.'), findsOneWidget);
        expect(find.text(AppStrings.retry), findsNothing);

        // 2. Replacing ProductPage with another seller's listing while block is in flight
        //    must not hide or close the new product when the older block completes.
        final productA = _product(id: 'p-a', userId: 'seller-a', name: 'Seller A Boots');
        final productB = _product(id: 'p-b', userId: 'seller-b', name: 'Seller B Shirt');
        final activeProduct = ValueNotifier<Product>(productA);
        addTearDown(activeProduct.dispose);

        await tester.pumpWidget(
          wrap(
            ValueListenableBuilder<Product>(
              valueListenable: activeProduct,
              builder: (_, product, _) => ProductPage(product: product),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Seller A Boots'), findsOneWidget);

        await tester.tap(find.byTooltip(AppStrings.productPageMoreActions));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.productPageBlockSeller));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, AppStrings.productPageBlockSellerConfirm));
        await tester.pump();

        // Replace displayed product while block request for seller-a is still pending.
        activeProduct.value = productB;
        await tester.pumpAndSettle();
        expect(find.text('Seller B Shirt'), findsOneWidget);

        // Complete the earlier block for seller-a.
        blockCompleter.complete(Result.success(const {'success': true}));
        await tester.pumpAndSettle();

        expect(blockedUsers.contains('seller-a'), isTrue);
        expect(find.text('Seller B Shirt'), findsOneWidget);
        expect(find.text('This listing is no longer available.'), findsNothing);
      },
    );
  });
}
