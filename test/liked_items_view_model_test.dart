import 'dart:async';

import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/liked_items/liked_items_view_model.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/unexpected_api_service.dart';

class _FakeProductRepository extends ProductRepository {
  _FakeProductRepository({
    this.fetchResult,
    this.unlikeResult,
    this.fetchCompleter,
    this.likeCompleter,
    this.fetchCharitiesResult,
    this.unlikeCharityResult,
    this.fetchCharitiesCompleter,
    this.likeCharityCompleter,
  }) : super(const UnexpectedApiService());

  Result<List<Product>>? fetchResult;
  Result<ProductLikeUpdate>? unlikeResult;
  Completer<Result<List<Product>>>? fetchCompleter;
  Completer<Result<ProductLikeUpdate>>? likeCompleter;
  final unlikedIds = <String>[];

  Result<List<Charity>>? fetchCharitiesResult;
  Result<CharityLikeUpdate>? unlikeCharityResult;
  Completer<Result<List<Charity>>>? fetchCharitiesCompleter;
  Completer<Result<CharityLikeUpdate>>? likeCharityCompleter;
  final unlikedCharityIds = <String>[];

  @override
  Future<Result<ProductLikeUpdate>> likeProduct(Product product) async {
    return likeCompleter?.future ??
        Result.success(
          ProductLikeUpdate(liked: true, likes: product.likes + 1),
        );
  }

  @override
  Future<Result<List<Product>>> fetchLikedProducts() async {
    return fetchCompleter?.future ??
        fetchResult ??
        Result.success(const <Product>[]);
  }

  @override
  Future<Result<ProductLikeUpdate>> unlikeProduct(String productId) async {
    unlikedIds.add(productId);
    return unlikeResult ??
        Result.success(const ProductLikeUpdate(liked: false, likes: 0));
  }

  @override
  Future<Result<CharityLikeUpdate>> likeCharity(Charity charity) async {
    return likeCharityCompleter?.future ??
        Result.success(
          CharityLikeUpdate(
            liked: true,
            likes: charity.likes + 1,
            charity: charity.copyWith(likes: charity.likes + 1),
          ),
        );
  }

  @override
  Future<Result<List<Charity>>> fetchLikedCharities() async {
    return fetchCharitiesCompleter?.future ??
        fetchCharitiesResult ??
        Result.success(const <Charity>[]);
  }

  @override
  Future<Result<CharityLikeUpdate>> unlikeCharity(String charityId) async {
    unlikedCharityIds.add(charityId);
    return unlikeCharityResult ??
        Result.success(const CharityLikeUpdate(liked: false, likes: 0));
  }
}

Charity _charity({
  String id = 'ca6tjKqCRurG0hB49Dcp',
  String name = 'WaterAid',
  int likes = 1,
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

Product _product({String id = 'liked-product'}) {
  return Product(
    id: id,
    name: 'Liked item',
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

void main() {
  group('LikedItemsViewModel', () {
    test('loads liked products and marks them as liked in shared state', () async {
      final repository = _FakeProductRepository(
        fetchResult: Result.success([_product()]),
      );
      final productViewModel = ProductViewModel(
        productRepository: repository,
        navigator: NavigationProvider(),
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: productViewModel,
      );

      await viewModel.loadLikedProducts();

      expect(viewModel.status, LikedItemsStatus.loaded);
      expect(viewModel.products, hasLength(1));
      expect(productViewModel.isProductLiked('liked-product'), isTrue);
    });

    test('uses cached liked products when the API response is empty', () async {
      final product = _product();
      final repository = _FakeProductRepository(
        fetchResult: Result.success(const <Product>[]),
      );
      final productViewModel = ProductViewModel(
        productRepository: repository,
        navigator: NavigationProvider(),
      )..cacheLikedProducts([product]);
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: productViewModel,
      );

      await viewModel.loadLikedProducts();

      expect(viewModel.status, LikedItemsStatus.loaded);
      expect(viewModel.products, [product]);
    });

    test('sets empty state when there are no liked products', () async {
      final repository = _FakeProductRepository(
        fetchResult: Result.success(const <Product>[]),
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: ProductViewModel(
          productRepository: repository,
          navigator: NavigationProvider(),
        ),
      );

      await viewModel.loadLikedProducts();

      expect(viewModel.status, LikedItemsStatus.empty);
      expect(viewModel.products, isEmpty);
    });

    test('sets error state when liked products fail to load', () async {
      final repository = _FakeProductRepository(
        fetchResult: Result.failure('Load failed'),
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: ProductViewModel(
          productRepository: repository,
          navigator: NavigationProvider(),
        ),
      );

      await viewModel.loadLikedProducts();

      expect(viewModel.status, LikedItemsStatus.error);
      expect(viewModel.errorMessage, 'Load failed');
    });

    test('unlike removes a product after the repository write succeeds', () async {
      final product = _product();
      final repository = _FakeProductRepository(
        fetchResult: Result.success([product]),
      );
      final productViewModel = ProductViewModel(
        productRepository: repository,
        navigator: NavigationProvider(),
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: productViewModel,
      );

      await viewModel.loadLikedProducts();
      final removed = await viewModel.unlikeProduct(product);

      expect(removed, isTrue);
      expect(repository.unlikedIds, ['liked-product']);
      expect(viewModel.status, LikedItemsStatus.empty);
      expect(viewModel.products, isEmpty);
      expect(productViewModel.isProductLiked('liked-product'), isFalse);
    });

    test('failed unlike keeps the product visible', () async {
      final product = _product();
      final repository = _FakeProductRepository(
        fetchResult: Result.success([product]),
        unlikeResult: Result.failure('Unlike failed'),
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: ProductViewModel(
          productRepository: repository,
          navigator: NavigationProvider(),
        ),
      );

      await viewModel.loadLikedProducts();
      final removed = await viewModel.unlikeProduct(product);

      expect(removed, isFalse);
      expect(viewModel.products, [product]);
      expect(viewModel.errorMessage, 'Unlike failed');
    });

    test('does not expose cached likes after the account changes', () {
      var currentUserId = 'account-a';
      final product = _product();
      final repository = _FakeProductRepository();
      final productViewModel = ProductViewModel(
        productRepository: repository,
        navigator: NavigationProvider(),
        currentUserIdProvider: () => currentUserId,
      )..cacheLikedProducts([product]);

      currentUserId = 'account-b';

      expect(productViewModel.cachedLikedProducts, isEmpty);
      expect(productViewModel.isProductLiked(product.id), isFalse);
    });

    test('clears an open liked-items view when user state is reset', () async {
      final product = _product();
      final repository = _FakeProductRepository(
        fetchResult: Result.success([product]),
      );
      final productViewModel = ProductViewModel(
        productRepository: repository,
        navigator: NavigationProvider(),
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: productViewModel,
      );

      await viewModel.loadLikedProducts();
      expect(viewModel.products, [product]);

      productViewModel.clearUserState();

      expect(viewModel.status, LikedItemsStatus.empty);
      expect(viewModel.products, isEmpty);
      viewModel.dispose();
    });

    test('clears an open liked-items view after an account change', () async {
      var currentUserId = 'account-a';
      final product = _product();
      final repository = _FakeProductRepository(
        fetchResult: Result.success([product]),
      );
      final productViewModel = ProductViewModel(
        productRepository: repository,
        navigator: NavigationProvider(),
        currentUserIdProvider: () => currentUserId,
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: productViewModel,
      );

      await viewModel.loadLikedProducts();
      expect(viewModel.products, [product]);

      currentUserId = 'account-b';
      productViewModel.isProductLiked(product.id);
      await Future<void>.microtask(() {});

      expect(viewModel.status, LikedItemsStatus.empty);
      expect(viewModel.products, isEmpty);
      viewModel.dispose();
    });

    test('ignores a liked-items response from the previous account', () async {
      var currentUserId = 'account-a';
      final fetchCompleter = Completer<Result<List<Product>>>();
      final repository = _FakeProductRepository(fetchCompleter: fetchCompleter);
      final productViewModel = ProductViewModel(
        productRepository: repository,
        navigator: NavigationProvider(),
        currentUserIdProvider: () => currentUserId,
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: productViewModel,
      );

      final loadFuture = viewModel.loadLikedProducts();
      currentUserId = 'account-b';
      fetchCompleter.complete(Result.success([_product()]));
      await loadFuture;

      expect(viewModel.status, LikedItemsStatus.empty);
      expect(viewModel.products, isEmpty);
      expect(productViewModel.cachedLikedProducts, isEmpty);
    });

    test(
      'ignores a like response completed after the account changes',
      () async {
        var currentUserId = 'account-a';
        final likeCompleter = Completer<Result<ProductLikeUpdate>>();
        final product = _product();
        final repository = _FakeProductRepository(likeCompleter: likeCompleter);
        final productViewModel = ProductViewModel(
          productRepository: repository,
          navigator: NavigationProvider(),
          currentUserIdProvider: () => currentUserId,
        );

        final likeFuture = productViewModel.setProductLiked(product, true);
        expect(productViewModel.isLikeUpdatePending(product.id), isTrue);

        currentUserId = 'account-b';
        likeCompleter.complete(
          Result.success(const ProductLikeUpdate(liked: true, likes: 1)),
        );
        final result = await likeFuture;

        expect(result.isSuccess, isFalse);
        expect(productViewModel.isLikeUpdatePending(product.id), isFalse);
        expect(productViewModel.isProductLiked(product.id), isFalse);
        expect(productViewModel.cachedLikedProducts, isEmpty);
      },
    );

    test('selecting charities tab loads liked charities and marks them as liked', () async {
      final charity = _charity(likes: 4);
      final repository = _FakeProductRepository(
        fetchCharitiesResult: Result.success([charity]),
      );
      final productViewModel = ProductViewModel(
        productRepository: repository,
        navigator: NavigationProvider(),
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: productViewModel,
      );

      viewModel.selectTab(LikedItemsTab.charities);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.selectedTab, LikedItemsTab.charities);
      expect(viewModel.charitiesStatus, LikedItemsStatus.loaded);
      expect(viewModel.charities, hasLength(1));
      expect(viewModel.charities.first.id, charity.id);
      expect(productViewModel.isCharityLiked(charity.id), isTrue);
      expect(productViewModel.getCharityLikesCount(charity.id), 4);
    });

    test('sets empty state when there are no liked charities', () async {
      final repository = _FakeProductRepository(
        fetchCharitiesResult: Result.success(const <Charity>[]),
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: ProductViewModel(
          productRepository: repository,
          navigator: NavigationProvider(),
        ),
      );

      await viewModel.loadLikedCharities();

      expect(viewModel.charitiesStatus, LikedItemsStatus.empty);
      expect(viewModel.charities, isEmpty);
    });

    test('unlikeCharity removes a charity and updates shared heart and count', () async {
      final charity = _charity(likes: 1);
      final repository = _FakeProductRepository(
        fetchCharitiesResult: Result.success([charity]),
      );
      final productViewModel = ProductViewModel(
        productRepository: repository,
        navigator: NavigationProvider(),
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: productViewModel,
      );

      await viewModel.loadLikedCharities();
      expect(productViewModel.isCharityLiked(charity.id), isTrue);
      expect(productViewModel.getCharityLikesCount(charity.id), 1);

      final removed = await viewModel.unlikeCharity(charity);

      expect(removed, isTrue);
      expect(repository.unlikedCharityIds, [charity.id]);
      expect(viewModel.charitiesStatus, LikedItemsStatus.empty);
      expect(viewModel.charities, isEmpty);
      expect(productViewModel.isCharityLiked(charity.id), isFalse);
      expect(productViewModel.getCharityLikesCount(charity.id), 0);
    });

    test('failed unlikeCharity keeps the charity visible', () async {
      final charity = _charity(likes: 2);
      final repository = _FakeProductRepository(
        fetchCharitiesResult: Result.success([charity]),
        unlikeCharityResult: Result.failure('Unable to unlike charity'),
      );
      final viewModel = LikedItemsViewModel(
        productRepository: repository,
        productViewModel: ProductViewModel(
          productRepository: repository,
          navigator: NavigationProvider(),
        ),
      );

      await viewModel.loadLikedCharities();
      final removed = await viewModel.unlikeCharity(charity);

      expect(removed, isFalse);
      expect(viewModel.charities, hasLength(1));
      expect(viewModel.charitiesErrorMessage, 'Unable to unlike charity');
    });
  });
}
