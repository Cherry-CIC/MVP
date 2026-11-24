import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/products/blocked_users.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';

final class ProductLikeUpdate {
  const ProductLikeUpdate({required this.liked, required this.likes});

  final bool liked;
  final int likes;
}

final class CharityLikeUpdate {
  const CharityLikeUpdate({
    required this.liked,
    required this.likes,
    this.charity,
  });

  final bool liked;
  final int likes;
  final Charity? charity;
}

class ProductRepository {
  ProductRepository(this._apiService, {this.deletedListings, this.blockedUsers});

  static const int _likedProductsPageLimit = 50;
  static const int _likedCharitiesPageLimit = 50;
  static const String _loadFailureMessage = 'We couldn’t load your liked items.';
  static const String _loadCharitiesFailureMessage = 'We couldn’t load your liked charities.';

  final ApiService _apiService;
  final DeletedListings? deletedListings;
  final BlockedUsers? blockedUsers;

  Future<Result<Product>> fetchProduct(String productId) async {
    final validationError = _validateProductId(productId);
    if (validationError != null) {
      return Result.failure(validationError);
    }
    if (deletedListings?.contains(productId) ?? false) {
      return _deletedListingFailure();
    }

    const failureMessage = 'We couldn’t load this listing.';

    try {
      final blockedHydration = blockedUsers?.ensureHydrated();
      final result = await _apiService.get<dynamic>(
        ApiEndpoints.productWithDetailsById(productId),
      );
      if (blockedHydration != null) {
        await blockedHydration;
      }
      // A response which started before deletion must not restore the listing.
      if (deletedListings?.contains(productId) ?? false) {
        return _deletedListingFailure();
      }
      if (blockedUsers != null && !blockedUsers!.isAuthoritative) {
        return Result.failure(failureMessage);
      }
      if (!result.isSuccess) {
        return Result.failure(
          result.error ?? failureMessage,
          statusCode: result.statusCode,
          errorCode: result.errorCode,
        );
      }

      final response = result.value;
      if (response is! Map || response['success'] != true) {
        return Result.failure(failureMessage);
      }

      final productData = response['data'];
      if (productData is! Map) {
        return Result.failure(failureMessage);
      }

      final json = Map<String, dynamic>.from(productData);
      // The API permits listings without a description.
      json['description'] ??= '';
      final product = Product.fromJson(json);
      // Ownership must be known before the detail page can offer buyer actions.
      if (product.id != productId || (product.userId?.trim().isEmpty ?? true)) {
        return Result.failure(failureMessage);
      }
      if (blockedUsers?.contains(product.userId) ?? false) {
        return _deletedListingFailure();
      }

      return Result.success(product);
    } catch (_) {
      return Result.failure(failureMessage);
    }
  }

  Future<Result<void>> deleteProduct(String productId) async {
    final validationError = _validateProductId(productId);
    if (validationError != null) {
      return Result.failure(validationError);
    }

    const failureMessage = 'We couldn’t confirm that this listing was deleted.';
    try {
      final result = await _apiService.delete<dynamic>(
        ApiEndpoints.productById(productId),
      );
      if (!result.isSuccess) {
        return Result.failure(
          failureMessage,
          statusCode: result.statusCode,
          errorCode: result.errorCode,
        );
      }
      final response = result.value;
      if (result.statusCode != 200 || response is! Map || response['success'] != true) {
        return Result.failure(failureMessage, statusCode: result.statusCode);
      }
      // The deletion response deliberately contains data:null. Recording the
      // tombstone belongs to the caller after checking the account is unchanged.
      return Result.success(null, statusCode: result.statusCode);
    } catch (_) {
      return Result.failure(failureMessage);
    }
  }

  Result<Product> _deletedListingFailure() => Result.failure(
    'This listing is no longer available.',
    statusCode: 404,
    errorCode: 'LISTING_NOT_FOUND',
  );

  Future<Result<ProductLikeUpdate>> likeProduct(Product product) async {
    return _setProductLiked(product.id, liked: true);
  }

  Future<Result<ProductLikeUpdate>> unlikeProduct(String productId) async {
    return _setProductLiked(productId, liked: false);
  }

  Future<Result<CharityLikeUpdate>> likeCharity(Charity charity) async {
    return _setCharityLiked(charity.id, liked: true);
  }

  Future<Result<CharityLikeUpdate>> unlikeCharity(String charityId) async {
    return _setCharityLiked(charityId, liked: false);
  }

  Future<Result<List<Charity>>> fetchCharities() async {
    try {
      final result = await _apiService.get<dynamic>(ApiEndpoints.charities);
      if (!result.isSuccess) {
        return Result.failure(result.error ?? 'Failed to fetch charities');
      }

      final response = result.value;
      if (_isUnsuccessfulResponse(response)) {
        return Result.failure('Failed to fetch charities');
      }

      final charityList = _extractCharityList(response);
      if (charityList == null) {
        return Result.success(const <Charity>[]);
      }

      return Result.success(_parseCharityList(charityList));
    } catch (_) {
      return Result.failure('Failed to fetch charities');
    }
  }

  Future<Result<List<Charity>>> fetchLikedCharities() async {
    try {
      final result = await _apiService.get<dynamic>(
        ApiEndpoints.likedCharities,
        queryParameters: const {'limit': _likedCharitiesPageLimit},
      );
      if (!result.isSuccess) {
        return Result.failure(result.error ?? _loadCharitiesFailureMessage);
      }

      final response = result.value;
      if (_isUnsuccessfulResponse(response)) {
        return Result.failure(_loadCharitiesFailureMessage);
      }

      final charityList = _extractCharityList(response);
      if (charityList == null) {
        return Result.success(const <Charity>[]);
      }

      return Result.success(_parseCharityList(charityList));
    } catch (_) {
      return Result.failure(_loadCharitiesFailureMessage);
    }
  }

  Future<Result<List<Product>>> fetchLikedProducts() async {
    try {
      final blockedHydration = blockedUsers?.ensureHydrated();
      final result = await _apiService.get<dynamic>(
        ApiEndpoints.likedProducts,
        queryParameters: const {'limit': _likedProductsPageLimit},
      );
      if (blockedHydration != null) {
        await blockedHydration;
      }
      if (blockedUsers != null && !blockedUsers!.isAuthoritative) {
        return Result.failure(_loadFailureMessage);
      }
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
          if ((blockedUsers?.contains(product.userId) ?? false) ||
              (deletedListings?.contains(product.id) ?? false)) {
            continue;
          }
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

  Future<Result<CharityLikeUpdate>> _setCharityLiked(
    String charityId, {
    required bool liked,
  }) async {
    final validationError = _validateCharityId(charityId);
    if (validationError != null) {
      return Result.failure(validationError);
    }

    final failureMessage = liked
        ? 'Unable to save this liked charity. Please try again.'
        : 'Unable to remove this liked charity. Please try again.';

    try {
      final result = await _apiService.post<dynamic>(
        ApiEndpoints.charityLike(charityId),
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

      Charity? parsedCharity;
      try {
        parsedCharity = Charity.fromJson(Map<String, dynamic>.from(responseData));
      } catch (_) {
        parsedCharity = null;
      }

      return Result.success(
        CharityLikeUpdate(
          liked: liked,
          likes: likes,
          charity: parsedCharity,
        ),
      );
    } catch (_) {
      return Result.failure(failureMessage);
    }
  }

  List<Charity> _parseCharityList(List<dynamic> charityList) {
    final charities = <Charity>[];
    final seenCharityIds = <String>{};

    for (final charityData in charityList) {
      if (charityData is! Map) {
        continue;
      }

      try {
        final charity = Charity.fromJson(
          Map<String, dynamic>.from(charityData),
        );
        if (charity.id.trim().isNotEmpty && seenCharityIds.add(charity.id)) {
          charities.add(charity);
        }
      } catch (_) {
        continue;
      }
    }

    return charities;
  }

  List<dynamic>? _extractCharityList(dynamic response) {
    if (response is List) {
      return response;
    }
    if (response is! Map) {
      return null;
    }

    final data = response['data'];
    if (data is List) {
      return data;
    }
    if (data is Map && data['charities'] is List) {
      return data['charities'] as List<dynamic>;
    }
    if (response['charities'] is List) {
      return response['charities'] as List<dynamic>;
    }

    return null;
  }

  String? _validateCharityId(String charityId) {
    if (charityId.trim().isEmpty || charityId.contains('/')) {
      return 'Invalid charity ID.';
    }

    return null;
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
