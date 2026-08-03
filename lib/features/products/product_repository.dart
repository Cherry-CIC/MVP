import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';

final class ProductLikeUpdate {
  const ProductLikeUpdate({required this.liked, required this.likes});

  final bool liked;
  final int likes;
}

class ProductRepository {
  ProductRepository(this._apiService);

  static const int _likedProductsPageLimit = 50;
  static const String _loadFailureMessage = 'We couldn’t load your liked items.';

  final ApiService _apiService;

  Future<Result<ProductLikeUpdate>> likeProduct(Product product) async {
    return _setProductLiked(product.id, liked: true);
  }

  Future<Result<ProductLikeUpdate>> unlikeProduct(String productId) async {
    return _setProductLiked(productId, liked: false);
  }

  Future<Result<List<Product>>> fetchLikedProducts() async {
    try {
      final result = await _apiService.get<dynamic>(
        ApiEndpoints.likedProducts,
        queryParameters: const {'limit': _likedProductsPageLimit},
      );
      if (!result.isSuccess) {
        return Result.failure(result.error ?? _loadFailureMessage);
      }

      final response = result.value;
      if (_isUnsuccessfulResponse(response)) {
        return Result.failure(_loadFailureMessage);
      }

      final productList = _extractProductList(response);
      if (productList == null) {
        return Result.success(const <Product>[]);
      }

      final products = <Product>[];
      final seenProductIds = <String>{};

      for (final productData in productList) {
        if (productData is! Map) {
          continue;
        }

        try {
          final product = Product.fromJson(
            Map<String, dynamic>.from(productData),
          );
          if (seenProductIds.add(product.id)) {
            products.add(product);
          }
        } catch (_) {
          continue;
        }
      }

      return Result.success(products);
    } catch (_) {
      return Result.failure(_loadFailureMessage);
    }
  }

  Future<Result<ProductLikeUpdate>> _setProductLiked(
    String productId, {
    required bool liked,
  }) async {
    final validationError = _validateProductId(productId);
    if (validationError != null) {
      return Result.failure(validationError);
    }

    final failureMessage = liked
        ? 'Unable to save this liked item. Please try again.'
        : 'Unable to remove this liked item. Please try again.';

    try {
      final result = await _apiService.post<dynamic>(
        ApiEndpoints.productLike(productId),
        data: {'like': liked},
      );
      if (!result.isSuccess) {
        return Result.failure(result.error ?? failureMessage);
      }

      final response = result.value;
      if (response is! Map || response['success'] != true) {
        return Result.failure(failureMessage);
      }

      final responseData = response['data'];
      if (responseData is! Map || responseData['liked'] != liked) {
        return Result.failure(failureMessage);
      }

      final likes = _parseLikeCount(responseData['likes']);
      if (likes == null) {
        return Result.failure(failureMessage);
      }

      return Result.success(ProductLikeUpdate(liked: liked, likes: likes));
    } catch (_) {
      return Result.failure(failureMessage);
    }
  }

  int? _parseLikeCount(dynamic value) {
    final likes = switch (value) {
      int() => value,
      String() => int.tryParse(value),
      _ => null,
    };

    return likes != null && likes >= 0 ? likes : null;
  }

  bool _isUnsuccessfulResponse(dynamic response) {
    return response is Map && response['success'] == false;
  }

  List<dynamic>? _extractProductList(dynamic response) {
    if (response is! Map) {
      return null;
    }

    final data = response['data'];
    if (data is! Map) {
      return null;
    }

    final products = data['products'];
    return products is List ? products : null;
  }

  String? _validateProductId(String productId) {
    if (productId.trim().isEmpty || productId.contains('/')) {
      return 'Invalid product ID.';
    }

    return null;
  }
}
