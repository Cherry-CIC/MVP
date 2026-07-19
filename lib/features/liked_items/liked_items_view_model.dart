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
  });

  final ProductRepository productRepository;
  final ProductViewModel productViewModel;

  LikedItemsStatus _status = LikedItemsStatus.initial;
  List<Product> _products = const [];
  String? _errorMessage;

  LikedItemsStatus get status => _status;
  List<Product> get products => _products;
  String? get errorMessage => _errorMessage;

  Future<void> loadLikedProducts() async {
    _status = LikedItemsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await productRepository.fetchLikedProducts();

    if (!result.isSuccess) {
      _products = const [];
      _status = LikedItemsStatus.error;
      _errorMessage = result.error ?? 'We couldn’t load your liked items.';
      notifyListeners();
      return;
    }

    _products = result.value ?? const [];
    productViewModel.cacheLikedProducts(_products);
    _status = _products.isEmpty ? LikedItemsStatus.empty : LikedItemsStatus.loaded;
    notifyListeners();
  }

  Future<bool> unlikeProduct(Product product) async {
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      return true;
    }

    final result = await productViewModel.setProductLiked(product, false);
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
}
