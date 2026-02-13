import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:flutter/cupertino.dart';

class ProductViewModel extends ChangeNotifier {
  Product? _product;
  bool _isLiked = false;
  int _localLikesOffset = 0;

  Product? get product => _product;
  bool get isLiked => _isLiked;
  
  int get likesCount {
    if (_product == null) return 0;
    return _product!.likes + _localLikesOffset;
  }

  final ProductRepository productRepository;

  ProductViewModel({required this.productRepository});

  void setProduct(Product product) {
    _product = product;
    _isLiked = false; // Reset for new product, in future this would come from backend
    _localLikesOffset = 0;
    notifyListeners();
  }

  void toggleLike() {
    if (_product == null) return;
    
    _isLiked = !_isLiked;
    _localLikesOffset = _isLiked ? 1 : 0;
    
    // In the future, this is where the backend call would go:
    // productRepository.likeProduct(_product!.id, _isLiked);
    
    notifyListeners();
  }
}
