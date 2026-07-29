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
  final Map<String, Product> _likedProductCache = {};
  final Set<String> _pendingLikeUpdates = {};
  final String? Function() _currentUserIdProvider;
  int _accountStateVersion = 0;
  bool _accountOwnerInitialised = false;
  String? _accountOwnerId;

  Product? get product => _product;

  final ProductRepository productRepository;
  final NavigationProvider navigator;

  ProductViewModel({
    required this.productRepository,
    required this.navigator,
    String? Function()? currentUserIdProvider,
  }) : _currentUserIdProvider = currentUserIdProvider ?? _unauthenticatedUserId;

  static String? _unauthenticatedUserId() => null;

  int get accountStateVersion {
    _ensureCurrentAccount();
    return _accountStateVersion;
  }

  bool isAccountStateCurrent(int version) {
    _ensureCurrentAccount();
    return version == _accountStateVersion;
  }

  // Check if a specific product is liked
  bool isProductLiked(String productId) {
    _ensureCurrentAccount();
    return _likedProducts[productId] ?? false;
  }

  bool isLikeUpdatePending(String productId) {
    _ensureCurrentAccount();
    return _pendingLikeUpdates.contains(productId);
  }

  List<Product> get cachedLikedProducts {
    _ensureCurrentAccount();
    final products = <Product>[];
    for (final entry in _likedProductCache.entries) {
      if (_likedProducts[entry.key] == true) {
        products.add(entry.value);
      }
    }
    return List.unmodifiable(products);
  }

  // Get dynamic count for a product
  int getLikesCount(Product product) {
    _ensureCurrentAccount();
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
    _ensureCurrentAccount();
    final accountStateVersion = _accountStateVersion;
    final id = product.id;
    if (id.trim().isEmpty || _pendingLikeUpdates.contains(id)) {
      return Result.failure('Unable to update this liked item.');
    }

    _pendingLikeUpdates.add(id);
    notifyListeners();

    final result = liked ? await productRepository.likeProduct(product) : await productRepository.unlikeProduct(id);

    if (!isAccountStateCurrent(accountStateVersion)) {
      return Result.failure('Unable to update this liked item.');
    }

    _pendingLikeUpdates.remove(id);

    if (result.isSuccess) {
      _likedProducts[id] = liked;
      if (liked) {
        _likedProductCache[id] = product;
      } else {
        _likedProductCache.remove(id);
      }
      notifyListeners();
      return Result.success(liked);
    }

    notifyListeners();
    return Result.failure(result.error ?? 'Unable to update this liked item.');
  }

  void setCachedLikeState(String productId, bool liked) {
    _ensureCurrentAccount();
    if (productId.trim().isEmpty) {
      return;
    }

    _likedProducts[productId] = liked;
    if (!liked) {
      _likedProductCache.remove(productId);
    }
    notifyListeners();
  }

  void cacheLikedProducts(Iterable<Product> products) {
    _ensureCurrentAccount();
    var changed = false;

    for (final product in products) {
      if (product.id.trim().isEmpty) {
        continue;
      }

      if (_likedProducts[product.id] != true) {
        _likedProducts[product.id] = true;
        changed = true;
      }

      if (_likedProductCache[product.id] != product) {
        _likedProductCache[product.id] = product;
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void clearUserState() {
    _resetAccountState(_currentUserIdProvider());
    notifyListeners();
  }

  void _ensureCurrentAccount() {
    final currentUserId = _currentUserIdProvider();
    if (!_accountOwnerInitialised) {
      _accountOwnerId = currentUserId;
      _accountOwnerInitialised = true;
      return;
    }

    if (_accountOwnerId != currentUserId) {
      _resetAccountState(currentUserId);
    }
  }

  void _resetAccountState(String? currentUserId) {
    _likedProducts.clear();
    _likedProductCache.clear();
    _pendingLikeUpdates.clear();
    _accountOwnerId = currentUserId;
    _accountOwnerInitialised = true;
    _accountStateVersion += 1;
  }

  // For the Product Page (the currently active product)
  bool get isCurrentProductLiked => _product != null && isProductLiked(_product!.id);
  int get currentProductLikesCount => _product == null ? 0 : getLikesCount(_product!);

  Future<void> showPurchaseSecurity() async {
    await navigator.showPurchaseSecurity();
  }

  void goToProductPage(Product product) async {
    setProduct(product);
    await navigator.navigateTo(AppRoutes.product);
  }
}
