import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _HomeRepositoryStub implements IHomeRepository {
  const _HomeRepositoryStub(this.page);

  final ProductPage page;

  @override
  Future<Result<ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
  }) async {
    return Result.success(page);
  }
}

void main() {
  test(
    'reconciles local counts when Home receives authoritative products',
    () async {
      final product = _product(likes: 1);
      final reconciledProducts = <Product>[];
      final viewModel = HomeViewModel(
        homeRepository: _HomeRepositoryStub(
          ProductPage(
            products: [product],
            limit: 20,
            nextCursor: null,
            hasMore: false,
          ),
        ),
        onProductsLoaded: reconciledProducts.addAll,
      );

      await viewModel.fetchProducts();

      expect(reconciledProducts, [product]);
    },
  );
}

Product _product({required int likes}) {
  return Product(
    id: 'home-product',
    name: 'Home item',
    description: 'A home test product',
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
