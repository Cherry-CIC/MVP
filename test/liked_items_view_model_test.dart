import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/liked_items/liked_items_view_model.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository extends ProductRepository {
  _FakeProductRepository({
    this.fetchResult,
    this.unlikeResult,
  });

  Result<List<Product>>? fetchResult;
  Result<void>? unlikeResult;
  final unlikedIds = <String>[];

  @override
  Future<Result<List<Product>>> fetchLikedProducts() async {
    return fetchResult ?? Result.success(const <Product>[]);
  }

  @override
  Future<Result<void>> unlikeProduct(String productId) async {
    unlikedIds.add(productId);
    return unlikeResult ?? Result.success(null);
  }
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
  });
}
