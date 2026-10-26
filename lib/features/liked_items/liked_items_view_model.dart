import 'package:flutter/foundation.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';

enum LikedItemsStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

class LikedItemsViewModel extends ChangeNotifier {
  LikedItemsViewModel({
    required this.productRepository,
    required this.productViewModel,
    this.deletedListings,
  }) {
    _accountStateVersion = productViewModel.accountStateVersion;
    productViewModel.addListener(_handleProductStateChange);
    deletedListings?.addListener(_removeDeletedListings);
  }

  final ProductRepository productRepository;
  final ProductViewModel productViewModel;
  final DeletedListings? deletedListings;
  late int _accountStateVersion;
  int _requestSequence = 0;
  bool _disposed = false;

  LikedItemsStatus _status = LikedItemsStatus.initial;
  List<Product> _products = const [];
  String? _errorMessage;

  LikedItemsStatus get status => _status;
  List<Product> get products => _products;
  String? get errorMessage => _errorMessage;

  Future<void> loadLikedProducts() async {
    if (_disposed) return;
    final request = ++_requestSequence;
    final accountStateVersion = productViewModel.accountStateVersion;
    _accountStateVersion = accountStateVersion;
    _status = LikedItemsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await productRepository.fetchLikedProducts();

    if (_disposed || request != _requestSequence) return;
    if (!productViewModel.isAccountStateCurrent(accountStateVersion)) {
      _clearProductsAfterAccountChange();
      return;
    }

    if (!result.isSuccess) {
      _products = const [];
      _status = LikedItemsStatus.error;
      _errorMessage = result.error ?? 'We couldn’t load your liked items.';
      notifyListeners();
      return;
    }

    _products = _mergeProducts(
      result.value ?? const [],
      productViewModel.cachedLikedProducts,
    );
    productViewModel.cacheLikedProducts(_products);
    _status = _products.isEmpty ? LikedItemsStatus.empty : LikedItemsStatus.loaded;
    notifyListeners();
  }

  Future<bool> unlikeProduct(Product product) async {
    if (_disposed) return false;
    if (!_products.any((item) => item.id == product.id)) {
      return true;
    }

    final accountStateVersion = productViewModel.accountStateVersion;
    final result = await productViewModel.setProductLiked(product, false);
    if (_disposed) return false;
    if (!productViewModel.isAccountStateCurrent(accountStateVersion)) {
      _clearProductsAfterAccountChange();
      return false;
    }

    if (_isDeleted(product.id)) return true;

    if (!result.isSuccess) {
      _errorMessage = result.error ?? 'Unable to remove this liked item.';
      notifyListeners();
      return false;
    }

    // A deletion may have changed the list while the unlike request was pending.
    _products = List.unmodifiable(_products.where((item) => item.id != product.id));
    _status = _products.isEmpty ? LikedItemsStatus.empty : LikedItemsStatus.loaded;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<void> retry() {
    return loadLikedProducts();
  }

  void _clearProductsAfterAccountChange() {
    if (_disposed) return;
    _requestSequence++;
    _accountStateVersion = productViewModel.accountStateVersion;
    _products = const [];
    _status = LikedItemsStatus.empty;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleProductStateChange() {
    if (_disposed) return;
    if (!productViewModel.isAccountStateCurrent(_accountStateVersion)) {
      _clearProductsAfterAccountChange();
      return;
    }
    _removeDeletedListings();
  }

  List<Product> _mergeProducts(
    List<Product> primaryProducts,
    List<Product> cachedProducts,
  ) {
    final products = <Product>[];
    final seenProductIds = <String>{};

    for (final product in [...primaryProducts, ...cachedProducts]) {
      if (_isDeleted(product.id) || product.id.trim().isEmpty || !seenProductIds.add(product.id)) {
        continue;
      }
      products.add(product);
    }

    return List.unmodifiable(products);
  }

  bool _isDeleted(String id) => deletedListings?.contains(id) == true || productViewModel.isProductDeleted(id);

  void _removeDeletedListings() {
    if (_disposed) return;
    final products = _products.where((product) => !_isDeleted(product.id)).toList(growable: false);
    if (products.length == _products.length) return;
    _products = List.unmodifiable(products);
    if (_status == LikedItemsStatus.loaded || _status == LikedItemsStatus.empty) {
      _status = _products.isEmpty ? LikedItemsStatus.empty : LikedItemsStatus.loaded;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestSequence++;
    productViewModel.removeListener(_handleProductStateChange);
    deletedListings?.removeListener(_removeDeletedListings);
    super.dispose();
  }
}
