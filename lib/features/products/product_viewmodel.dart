import 'package:flutter/cupertino.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';

class ProductViewModel extends ChangeNotifier {
  Product? _product;

  // Centralized tracker: Map<ProductID, IsLiked>
  final Map<String, bool> _likedProducts = {};
  final Map<String, Product> _likedProductSnapshots = {};
  final Set<String> _pendingLikeUpdates = {};

  Product? get product => _product;

  final ProductRepository productRepository;
  final NavigationProvider navigator;

  ProductViewModel({required this.productRepository, required this.navigator});

  // Check if a specific product is liked
  bool isProductLiked(String productId) {
    return _likedProducts[productId] ?? false;
  }

  bool isLikeUpdatePending(String productId) {
    return _pendingLikeUpdates.contains(productId);
  }

  List<Product> get cachedLikedProducts {
    final products = <Product>[];
    for (final entry in _likedProductSnapshots.entries) {
      if (_likedProducts[entry.key] == true) {
        products.add(entry.value);
      }
    }
    return List.unmodifiable(products);
  }

  // Get dynamic count for a product
  int getLikesCount(Product product) {
    bool isLiked = _likedProducts[product.id] ?? false;
    return product.likes + (isLiked ? 1 : 0);
  }

  void setProduct(Product product) {
    _product = product;
    notifyListeners();
  }

  Future<Result<bool>> toggleLike(Product product) async {
    final String id = product.id;
    final bool currentStatus = _likedProducts[id] ?? false;

    return setProductLiked(product, !currentStatus);
  }

  Future<Result<bool>> setProductLiked(Product product, bool liked) async {
    final id = product.id;
    if (id.trim().isEmpty || _pendingLikeUpdates.contains(id)) {
      return Result.failure('Unable to update this liked item.');
    }

    _pendingLikeUpdates.add(id);
    notifyListeners();

    final result = liked ? await productRepository.likeProduct(product) : await productRepository.unlikeProduct(id);

    _pendingLikeUpdates.remove(id);

    if (result.isSuccess) {
      _likedProducts[id] = liked;
      if (liked) {
        _likedProductSnapshots[id] = product;
      } else {
        _likedProductSnapshots.remove(id);
      }
      notifyListeners();
      return Result.success(liked);
    }

    notifyListeners();
    return Result.failure(result.error ?? 'Unable to update this liked item.');
  }

  void setCachedLikeState(String productId, bool liked) {
    if (productId.trim().isEmpty) {
      return;
    }

    _likedProducts[productId] = liked;
    if (!liked) {
      _likedProductSnapshots.remove(productId);
    }
    notifyListeners();
  }

  void cacheLikedProducts(Iterable<Product> products) {
    var changed = false;

    for (final product in products) {
      if (product.id.trim().isEmpty) {
        continue;
      }

      if (_likedProducts[product.id] != true) {
        _likedProducts[product.id] = true;
        changed = true;
      }

      if (_likedProductSnapshots[product.id] != product) {
        _likedProductSnapshots[product.id] = product;
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  // For the Product Page (the currently active product)
  bool get isCurrentProductLiked => _product != null && (_likedProducts[_product!.id] ?? false);
  int get currentProductLikesCount => _product == null ? 0 : getLikesCount(_product!);

  Future<void> showPurchaseSecurity() async {
    await navigator.showPurchaseSecurity();
  }

  void goToProductPage(Product product) async {
    setProduct(product);
    await navigator.navigateTo(AppRoutes.product);
  }
}
