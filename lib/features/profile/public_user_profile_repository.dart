import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/profile/models/public_user.dart';

export 'package:cherry_mvp/features/profile/models/public_user.dart';

abstract class IPublicUserProfileRepository {
  Future<Result<PublicUserProfilePage>> fetchProfile(
    String userId, {
    int limit = 20,
    String? cursor,
  });
}

class PublicUserProfileRepository implements IPublicUserProfileRepository {
  final ApiService _apiService;

  PublicUserProfileRepository(this._apiService);

  static const _loadError = 'Could not load this profile. Please try again.';
  static const _unavailableError = 'This profile is unavailable.';

  @override
  Future<Result<PublicUserProfilePage>> fetchProfile(
    String userId, {
    int limit = 20,
    String? cursor,
  }) async {
    final requestedId = _identifier(userId);
    if (requestedId == null || requestedId == 'deleted_user') {
      return Result.failure(_unavailableError, statusCode: 404);
    }
    if (limit < 1 || limit > 50) {
      return Result.failure(_loadError);
    }
    final requestedCursor = _text(cursor);

    try {
      final result = await _apiService.get<dynamic>(
        ApiEndpoints.publicUserProfile(requestedId),
        queryParameters: {
          'limit': limit,
          'cursor': ?requestedCursor,
        },
      );
      if (!result.isSuccess) {
        return Result.failure(
          result.statusCode == 404 || result.statusCode == 410 ? _unavailableError : _loadError,
          statusCode: result.statusCode,
        );
      }

      final response = result.value;
      if (response is! Map || response['success'] != true) {
        return Result.failure(_loadError);
      }
      final data = response['data'];
      final meta = response['meta'];
      if (data is! Map || data['products'] is! List || meta is! Map) {
        return Result.failure(_loadError);
      }
      final rawUser = data['user'];
      if (rawUser is! Map || _identifier(rawUser['id']) != requestedId) {
        return Result.failure(_loadError);
      }
      final username = _text(rawUser['username']);
      if (username == null || (rawUser['profileImageUrl'] != null && rawUser['profileImageUrl'] is! String)) {
        return Result.failure(_loadError);
      }
      final rawLimit = meta['limit'];
      final rawHasMore = meta['hasMore'];
      final rawCursor = meta['nextCursor'];
      if (rawLimit is! int ||
          rawLimit < 1 ||
          rawLimit > 50 ||
          rawHasMore is! bool ||
          !meta.containsKey('nextCursor') ||
          (rawCursor != null && rawCursor is! String)) {
        return Result.failure(_loadError);
      }
      final nextCursor = _text(rawCursor);
      if ((rawHasMore && (nextCursor == null || nextCursor == requestedCursor)) ||
          (!rawHasMore && nextCursor != null)) {
        return Result.failure(_loadError);
      }

      final products = <Product>[];
      final seenIds = <String>{};
      for (final rawProduct in data['products'] as List) {
        final product = _publicProduct(rawProduct, requestedId);
        if (product != null && seenIds.add(product.id)) {
          products.add(product);
        }
      }

      return Result.success(
        PublicUserProfilePage(
          user: PublicUser(
            id: requestedId,
            username: username,
            profileImageUrl: _imageUrl(rawUser['profileImageUrl']),
          ),
          products: List.unmodifiable(products),
          nextCursor: nextCursor,
          hasMore: rawHasMore,
        ),
      );
    } catch (_) {
      // Never surface raw service exceptions or backend response bodies.
      return Result.failure(_loadError);
    }
  }

  /// Defence in depth only. The API must filter visibility and owner before
  /// pagination, and must never send private account fields in its response.
  Product? _publicProduct(dynamic value, String userId) {
    if (value is! Map ||
        value['status'] != 'active' ||
        value['visibility'] != 'public' ||
        _identifier(value['userId']) != userId) {
      return null;
    }
    final id = _identifier(value['id']);
    final name = _text(value['name']);
    final description = value['description'];
    final quality = _text(value['quality']);
    final size = _text(value['size']);
    final postageSizeId = _identifier(value['postageSize']);
    final price = _nonNegativeNumber(value['price']);
    final donation = _nonNegativeNumber(value['donation']);
    final securityFee = _nonNegativeNumber(value['securityFee']);
    final likes = _nonNegativeInteger(value['likes']);
    final number = _nonNegativeInteger(value['number']);
    final rawImages = value['product_images'];
    if (id == null ||
        name == null ||
        description is! String ||
        quality == null ||
        size == null ||
        postageSizeId == null ||
        price == null ||
        donation == null ||
        (value['securityFee'] != null && securityFee == null) ||
        likes == null ||
        number == null ||
        number < 1 ||
        rawImages is! List) {
      return null;
    }
    final images = rawImages.map(_imageUrl).whereType<String>().toList(growable: false);
    return Product(
      id: id,
      userId: userId,
      name: name,
      description: description,
      quality: quality,
      productImages: List.unmodifiable(images),
      donation: donation,
      price: price,
      securityFee: securityFee,
      likes: likes,
      number: number,
      size: size,
      postageSizeId: postageSizeId,
      categoryId: _identifier(value['categoryId']),
      charityId: _identifier(value['charityId']),
      createdAt: _text(value['createdAt']),
      updatedAt: _text(value['updatedAt']),
      category: _publicCategory(value['category']),
      charity: _publicCharity(value['charity']),
    );
  }

  Category? _publicCategory(dynamic value) {
    if (value is! Map) return null;
    final id = _identifier(value['id']);
    final name = _text(value['name']);
    final createdAt = DateTime.tryParse(_text(value['createdAt']) ?? '');
    final updatedAt = DateTime.tryParse(_text(value['updatedAt']) ?? '');
    if (id == null || name == null || createdAt == null || updatedAt == null) return null;
    return Category(
      id: id,
      name: name,
      imageUrl: _imageUrl(value['imageUrl']) ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Charity? _publicCharity(dynamic value) {
    if (value is! Map) return null;
    final id = _identifier(value['id']);
    final name = _text(value['name']);
    final createdAt = DateTime.tryParse(_text(value['createdAt']) ?? '');
    final updatedAt = DateTime.tryParse(_text(value['updatedAt']) ?? '');
    if (id == null || name == null || createdAt == null || updatedAt == null) return null;
    return Charity(
      id: id,
      name: name,
      imageUrl: _imageUrl(value['imageUrl']) ?? '',
      description: _text(value['description']),
      website: _imageUrl(value['website']),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static String? _text(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static String? _identifier(dynamic value) {
    final id = _text(value);
    if (id == null || id == '.' || id == '..' || RegExp(r'[/\\\x00-\x1f\x7f]').hasMatch(id)) {
      return null;
    }
    return id;
  }

  static String? _imageUrl(dynamic value) {
    final text = _text(value);
    final uri = text == null ? null : Uri.tryParse(text);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      return null;
    }
    return text;
  }

  static double? _nonNegativeNumber(dynamic value) {
    final parsed = value is num ? value.toDouble() : (value is String ? double.tryParse(value) : null);
    return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : null;
  }

  static int? _nonNegativeInteger(dynamic value) {
    final parsed = value is int ? value : (value is String ? int.tryParse(value) : null);
    return parsed != null && parsed >= 0 ? parsed : null;
  }
}
