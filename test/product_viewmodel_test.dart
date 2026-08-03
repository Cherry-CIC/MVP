import 'dart:async';

import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/unexpected_api_service.dart';

class _LikeUpdateRepository extends ProductRepository {
  _LikeUpdateRepository({
    required this.likeUpdate,
    required this.unlikeUpdate,
    this.likedProductsResult,
    this.likedProductsCompleters = const [],
  }) : super(const UnexpectedApiService());

  final ProductLikeUpdate likeUpdate;
  final ProductLikeUpdate unlikeUpdate;
  final Result<List<Product>>? likedProductsResult;
  final List<Completer<Result<List<Product>>>> likedProductsCompleters;
  int fetchLikedProductsCount = 0;

  @override
  Future<Result<List<Product>>> fetchLikedProducts() async {
    fetchLikedProductsCount++;
    if (fetchLikedProductsCount <= likedProductsCompleters.length) {
      return likedProductsCompleters[fetchLikedProductsCount - 1].future;
    }
    return likedProductsResult ?? Result.success(const <Product>[]);
  }

  @override
  Future<Result<ProductLikeUpdate>> likeProduct(Product product) async {
    return Result.success(likeUpdate);
  }

  @override
  Future<Result<ProductLikeUpdate>> unlikeProduct(String productId) async {
    return Result.success(unlikeUpdate);
  }
}

void main() {
  test(
    'keeps API like counts consistent across like, refresh and unlike',
    () async {
      final repository = _LikeUpdateRepository(
        likeUpdate: const ProductLikeUpdate(liked: true, likes: 1),
        unlikeUpdate: const ProductLikeUpdate(liked: false, likes: 0),
      );
      final viewModel = ProductViewModel(
        productRepository: repository,
        navigator: NavigationProvider(),
      );
      final originalHomeProduct = _product(likes: 0);

      expect(viewModel.getLikesCount(originalHomeProduct), 0);

      final liked = await viewModel.setProductLiked(originalHomeProduct, true);

      expect(liked.value, isTrue);
      expect(viewModel.isProductLiked(originalHomeProduct.id), isTrue);
      expect(viewModel.getLikesCount(originalHomeProduct), 1);

      final likedApiProduct = _product(likes: 2);
      viewModel.cacheLikedProducts([likedApiProduct]);

      expect(viewModel.getLikesCount(likedApiProduct), 2);
      expect(viewModel.getLikesCount(originalHomeProduct), 2);

      final refreshedHomeProduct = _product(likes: 1);
      viewModel.reconcileProductCounts([refreshedHomeProduct]);

      expect(viewModel.getLikesCount(refreshedHomeProduct), 1);

      final unliked = await viewModel.setProductLiked(
        refreshedHomeProduct,
        false,
      );

      expect(unliked.value, isFalse);
      expect(viewModel.isProductLiked(refreshedHomeProduct.id), isFalse);
      expect(viewModel.getLikesCount(refreshedHomeProduct), 0);

      final unlikedApiProduct = _product(likes: 0);
      viewModel.reconcileProductCounts([unlikedApiProduct]);

      expect(viewModel.getLikesCount(unlikedApiProduct), 0);
    },
  );

  test('uses an idempotent API count without adding another like', () async {
    final product = _product(likes: 1);
    final viewModel = ProductViewModel(
      productRepository: _LikeUpdateRepository(
        likeUpdate: const ProductLikeUpdate(liked: true, likes: 1),
        unlikeUpdate: const ProductLikeUpdate(liked: false, likes: 0),
      ),
      navigator: NavigationProvider(),
    );

    await viewModel.setProductLiked(product, true);

    expect(viewModel.getLikesCount(product), 1);
  });

  test('shares concurrent liked-state hydration requests', () async {
    final repository = _LikeUpdateRepository(
      likeUpdate: const ProductLikeUpdate(liked: true, likes: 1),
      unlikeUpdate: const ProductLikeUpdate(liked: false, likes: 0),
    );
    final viewModel = ProductViewModel(
      productRepository: repository,
      navigator: NavigationProvider(),
    );

    final firstHydration = viewModel.hydrateLikedProducts();
    final secondHydration = viewModel.hydrateLikedProducts();
    await Future.wait([firstHydration, secondHydration]);

    expect(identical(firstHydration, secondHydration), isTrue);
    expect(repository.fetchLikedProductsCount, 1);
  });

  test('restores liked state from the API after a fresh start', () async {
    final product = _product(likes: 1);
    final viewModel = ProductViewModel(
      productRepository: _LikeUpdateRepository(
        likeUpdate: const ProductLikeUpdate(liked: true, likes: 1),
        unlikeUpdate: const ProductLikeUpdate(liked: false, likes: 0),
        likedProductsResult: Result.success([product]),
      ),
      navigator: NavigationProvider(),
    );

    expect(viewModel.isProductLiked(product.id), isFalse);

    final result = await viewModel.hydrateLikedProducts();

    expect(result.isSuccess, isTrue);
    expect(viewModel.isProductLiked(product.id), isTrue);
    expect(viewModel.getLikesCount(product), 1);
  });

  test('keeps overlapping hydration results within their account', () async {
    var currentUserId = 'account-a';
    final accountAHydration = Completer<Result<List<Product>>>();
    final accountBHydration = Completer<Result<List<Product>>>();
    final repository = _LikeUpdateRepository(
      likeUpdate: const ProductLikeUpdate(liked: true, likes: 1),
      unlikeUpdate: const ProductLikeUpdate(liked: false, likes: 0),
      likedProductsCompleters: [accountAHydration, accountBHydration],
    );
    final viewModel = ProductViewModel(
      productRepository: repository,
      navigator: NavigationProvider(),
      currentUserIdProvider: () => currentUserId,
    );

    final firstHydration = viewModel.hydrateLikedProducts();
    currentUserId = 'account-b';
    viewModel.clearUserState();
    final secondHydration = viewModel.hydrateLikedProducts();

    expect(identical(firstHydration, secondHydration), isFalse);
    expect(repository.fetchLikedProductsCount, 2);

    accountAHydration.complete(
      Result.success([_product(id: 'account-a-product', likes: 1)]),
    );
    final firstResult = await firstHydration;

    expect(firstResult.isSuccess, isFalse);
    expect(viewModel.isProductLiked('account-a-product'), isFalse);

    final sharedSecondHydration = viewModel.hydrateLikedProducts();
    expect(identical(secondHydration, sharedSecondHydration), isTrue);
    expect(repository.fetchLikedProductsCount, 2);

    accountBHydration.complete(
      Result.success([_product(id: 'account-b-product', likes: 1)]),
    );
    final secondResult = await secondHydration;

    expect(secondResult.isSuccess, isTrue);
    expect(viewModel.isProductLiked('account-a-product'), isFalse);
    expect(viewModel.isProductLiked('account-b-product'), isTrue);
  });

  test('failed hydration clears stale user-specific liked state', () async {
    final product = _product(likes: 1);
    final viewModel = ProductViewModel(
      productRepository: _LikeUpdateRepository(
        likeUpdate: const ProductLikeUpdate(liked: true, likes: 1),
        unlikeUpdate: const ProductLikeUpdate(liked: false, likes: 0),
        likedProductsResult: Result.failure('Load failed'),
      ),
      navigator: NavigationProvider(),
    )..cacheLikedProducts([product]);

    final result = await viewModel.hydrateLikedProducts();

    expect(result.isSuccess, isFalse);
    expect(viewModel.isProductLiked(product.id), isFalse);
    expect(viewModel.cachedLikedProducts, isEmpty);
    expect(viewModel.getLikesCount(product), 1);
  });
}

Product _product({String id = 'liked-product', required int likes}) {
  return Product(
    id: id,
    name: 'Liked item',
    description: 'A liked test product',
    quality: 'GOOD',
    productImages: const [AppImages.product1],
    donation: 7,
    price: 7,
    securityFee: 1,
    likes: likes,
    number: 1,
    size: 'M',
    postageSizeId: 'small',
  );
}
