import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/unexpected_api_service.dart';

class _LikeUpdateRepository extends ProductRepository {
  _LikeUpdateRepository({required this.likeUpdate, required this.unlikeUpdate}) : super(const UnexpectedApiService());

  final ProductLikeUpdate likeUpdate;
  final ProductLikeUpdate unlikeUpdate;

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
}

Product _product({required int likes}) {
  return Product(
    id: 'liked-product',
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
