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
  final Map<String, int> _likeCountOverrides = {};
  final Set<String> _pendingLikeUpdates = {};
  final String? Function() _currentUserIdProvider;
  int _accountStateVersion = 0;
  bool _accountOwnerInitialised = false;
  String? _accountOwnerId;
  Future<Result<void>>? _likedProductsHydration;
  int? _likedProductsHydrationVersion;

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
    return _likeCountOverrides[product.id] ?? product.likes;
  }

  Future<Result<void>> hydrateLikedProducts() {
    _ensureCurrentAccount();
    final accountStateVersion = _accountStateVersion;
    final pendingHydration = _likedProductsHydration;
    if (pendingHydration != null &&
        _likedProductsHydrationVersion == accountStateVersion) {
      return pendingHydration;
    }

    final hydration = _hydrateLikedProducts(accountStateVersion);
    _likedProductsHydration = hydration;
    _likedProductsHydrationVersion = accountStateVersion;
    return hydration;
  }

  Future<Result<void>> _hydrateLikedProducts(int accountStateVersion) async {
    try {
      _clearCachedLikedState();

      final result = await productRepository.fetchLikedProducts();
      if (!isAccountStateCurrent(accountStateVersion)) {
        return Result.failure('Unable to restore liked items.');
      }

      if (!result.isSuccess) {
        return Result.failure(result.error ?? 'Unable to restore liked items.');
      }

      cacheLikedProducts(result.value ?? const []);
      return Result.success(null);
    } finally {
      if (_likedProductsHydrationVersion == accountStateVersion) {
        _likedProductsHydration = null;
        _likedProductsHydrationVersion = null;
      }
    }
  }

  void _clearCachedLikedState() {
    if (_likedProducts.isEmpty && _likedProductCache.isEmpty) {
      return;
    }

    _likedProducts.clear();
    _likedProductCache.clear();
    notifyListeners();
  }

  void setProduct(Product product) {
    _product = product;
    notifyListeners();
  }

  Future<Result<bool>> toggleLike(Product product) async {
    _ensureCurrentAccount();
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

    final update = result.value;
    if (result.isSuccess && update != null && update.liked == liked) {
      _likedProducts[id] = update.liked;
      _likeCountOverrides[id] = update.likes;
      if (update.liked) {
        _likedProductCache[id] = product;
      } else {
        _likedProductCache.remove(id);
      }
      notifyListeners();
      return Result.success(update.liked);
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

      if (_likeCountOverrides[product.id] != product.likes) {
        _likeCountOverrides[product.id] = product.likes;
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void reconcileProductCounts(Iterable<Product> products) {
    var changed = false;

    for (final product in products) {
      if (_likeCountOverrides.remove(product.id) != null) {
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
    _likedProductsHydration = null;
    _likedProductsHydrationVersion = null;
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
