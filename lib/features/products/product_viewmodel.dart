import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:flutter/cupertino.dart';

class ProductViewModel extends ChangeNotifier {
  Product? _product;
  
  // Centralized tracker: Map<ProductID, IsLiked>
  final Map<String, bool> _likedProducts = {};

  Product? get product => _product;

  final ProductRepository productRepository;

  ProductViewModel({required this.productRepository});

  // Check if a specific product is liked
  bool isProductLiked(String productId) {
    return _likedProducts[productId] ?? false;
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

  void toggleLike(Product product) {
    final String id = product.id;
    final bool currentStatus = _likedProducts[id] ?? false;
    
    _likedProducts[id] = !currentStatus;
    
    // In future: productRepository.likeProduct(id, !currentStatus);
    
    notifyListeners();
  }
  
  // For the Product Page (the currently active product)
  bool get isCurrentProductLiked => _product != null && (_likedProducts[_product!.id] ?? false);
  int get currentProductLikesCount => _product == null ? 0 : getLikesCount(_product!);
}
