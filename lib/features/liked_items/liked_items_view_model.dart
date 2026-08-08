import 'package:flutter/foundation.dart';
import 'package:cherry_mvp/core/models/product.dart';
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
  }) {
    _accountStateVersion = productViewModel.accountStateVersion;
    productViewModel.addListener(_handleProductStateChange);
  }

  final ProductRepository productRepository;
  final ProductViewModel productViewModel;
  late int _accountStateVersion;

  LikedItemsStatus _status = LikedItemsStatus.initial;
  List<Product> _products = const [];
  String? _errorMessage;

  LikedItemsStatus get status => _status;
  List<Product> get products => _products;
  String? get errorMessage => _errorMessage;

  Future<void> loadLikedProducts() async {
    final accountStateVersion = productViewModel.accountStateVersion;
    _accountStateVersion = accountStateVersion;
    _status = LikedItemsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await productRepository.fetchLikedProducts();

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
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      return true;
    }

    final accountStateVersion = productViewModel.accountStateVersion;
    final result = await productViewModel.setProductLiked(product, false);
    if (!productViewModel.isAccountStateCurrent(accountStateVersion)) {
      _clearProductsAfterAccountChange();
      return false;
    }

    if (!result.isSuccess) {
      _errorMessage = result.error ?? 'Unable to remove this liked item.';
      notifyListeners();
      return false;
    }

    final nextProducts = List<Product>.from(_products)..removeAt(index);
    _products = List.unmodifiable(nextProducts);
    _status = _products.isEmpty ? LikedItemsStatus.empty : LikedItemsStatus.loaded;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<void> retry() {
    return loadLikedProducts();
  }

  void _clearProductsAfterAccountChange() {
    _accountStateVersion = productViewModel.accountStateVersion;
    _products = const [];
    _status = LikedItemsStatus.empty;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleProductStateChange() {
    if (!productViewModel.isAccountStateCurrent(_accountStateVersion)) {
      _clearProductsAfterAccountChange();
    }
  }

  List<Product> _mergeProducts(
    List<Product> primaryProducts,
    List<Product> cachedProducts,
  ) {
    final products = <Product>[];
    final seenProductIds = <String>{};

    for (final product in [...primaryProducts, ...cachedProducts]) {
      if (product.id.trim().isEmpty || !seenProductIds.add(product.id)) {
        continue;
      }
      products.add(product);
    }

    return List.unmodifiable(products);
  }

  @override
  void dispose() {
    productViewModel.removeListener(_handleProductStateChange);
    super.dispose();
  }
}
