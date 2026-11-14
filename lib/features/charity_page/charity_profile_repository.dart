import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';

/// Page of listings belonging to a specific charity.
class CharityProfilePageData {
  const CharityProfilePageData({
    required this.charity,
    required this.products,
    required this.nextCursor,
    required this.hasMore,
  });

  final Charity charity;
  final List<Product> products;
  final String? nextCursor;
  final bool hasMore;
}

/// Contract for fetching a charity's metadata and active listings.
abstract class ICharityProfileRepository {
  Future<Result<Charity>> fetchCharity({
    String? charityId,
    String? charityName,
  });

  Future<Result<CharityProfilePageData>> fetchProducts(
    Charity charity, {
    int limit = 20,
    String? cursor,
  });
}

/// Loads charity profile details and listings via `/api/charities/:id` and `/products`.
class CharityProfileRepository implements ICharityProfileRepository {
  CharityProfileRepository(this._apiService);

  final ApiService _apiService;

  static const int _fallbackScanMaxPages = 5;
  static const int _fallbackScanPageSize = 50;

  @override
  Future<Result<Charity>> fetchCharity({
    String? charityId,
    String? charityName,
  }) async {
    final safeId = CharityProfileArgs.safeIdentifier(charityId);
    final trimmedName = charityName?.trim();

    if (safeId != null) {
      try {
        final response = await _apiService.get<dynamic>(
          ApiEndpoints.charityById(safeId),
        );
        if (response.isSuccess) {
          final parsed = _extractCharityFromSingleResponse(
            response.value,
            expectedId: safeId,
          );
          if (parsed != null) {
            return Result.success(parsed);
          }
          return Result.failure(AppStrings.charityProfileLoadError);
        }
        if (response.statusCode == 404 || response.statusCode == 410) {
          // If no fallback name was provided, respect the 404 directly.
          if (trimmedName == null || trimmedName.isEmpty) {
            return Result.failure(
              AppStrings.charityProfileUnavailable,
              statusCode: response.statusCode,
            );
          }
        } else if (trimmedName == null || trimmedName.isEmpty) {
          return Result.failure(
            AppStrings.charityProfileLoadError,
            statusCode: response.statusCode,
          );
        }
      } catch (_) {
        if (trimmedName == null || trimmedName.isEmpty) {
          return Result.failure(AppStrings.charityProfileLoadError);
        }
      }
    }

    if (trimmedName != null && trimmedName.isNotEmpty) {
      return _findCharityByName(trimmedName);
    }

    return Result.failure(
      AppStrings.charityProfileUnavailable,
      statusCode: 404,
    );
  }

  Future<Result<Charity>> _findCharityByName(String targetName) async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.charities);
      if (!response.isSuccess) {
        return Result.failure(
          response.statusCode == 404 || response.statusCode == 410
              ? AppStrings.charityProfileUnavailable
              : AppStrings.charityProfileLoadError,
          statusCode: response.statusCode,
        );
      }

      final charities = _extractCharityList(response.value);
      final normalizedTarget = _normalizeName(targetName);
      if (normalizedTarget.isEmpty) {
        return Result.failure(
          AppStrings.charityProfileUnavailable,
          statusCode: 404,
        );
      }
      for (final raw in charities) {
        final charity = _parseCharity(raw);
        if (charity != null &&
            _normalizeName(charity.name) == normalizedTarget) {
          return Result.success(charity);
        }
      }

      return Result.failure(
        AppStrings.charityProfileUnavailable,
        statusCode: 404,
      );
    } catch (_) {
      return Result.failure(AppStrings.charityProfileLoadError);
    }
  }

  @override
  Future<Result<CharityProfilePageData>> fetchProducts(
    Charity charity, {
    int limit = 20,
    String? cursor,
  }) async {
    final safeId = CharityProfileArgs.safeIdentifier(charity.id);
    if (safeId == null) {
      return Result.failure(
        AppStrings.charityProfileUnavailable,
        statusCode: 404,
      );
    }
    if (limit < 1 || limit > 50) {
      return Result.failure(AppStrings.charityProfileLoadError);
    }
    final requestedCursor = cursor?.trim();
    if (cursor != null &&
        (requestedCursor == null || requestedCursor.isEmpty)) {
      return Result.failure(AppStrings.charityProfileLoadError);
    }

    final query = <String>['limit=$limit'];
    if (requestedCursor != null) {
      query.add('cursor=${Uri.encodeQueryComponent(requestedCursor)}');
    }

    try {
      final response = await _apiService.get<dynamic>(
        '${ApiEndpoints.charityProducts(safeId)}?${query.join('&')}',
      );
      if (!response.isSuccess) {
        // Gracefully handle an older backend deployment that has not mounted
        // GET /api/charities/:id/products yet by filtering productsWithDetails.
        if (response.statusCode == 404 &&
            requestedCursor == null &&
            _looksLikeMissingRoute(response)) {
          return await _fetchProductsFallback(charity);
        }
        return Result.failure(
          response.statusCode == 404 || response.statusCode == 410
              ? AppStrings.charityProfileUnavailable
              : AppStrings.charityProfileLoadError,
          statusCode: response.statusCode,
        );
      }

      return _parseProductsPage(
        charity: charity,
        response: response.value,
        requestedCursor: requestedCursor,
      );
    } catch (_) {
      return Result.failure(AppStrings.charityProfileLoadError);
    }
  }

  bool _looksLikeMissingRoute(Result<dynamic> response) {
    final error = (response.error ?? '').toLowerCase();
    return !error.contains('charity not found');
  }

  Future<Result<CharityProfilePageData>> _fetchProductsFallback(
    Charity charity,
  ) async {
    final matched = <Product>[];
    final seenIds = <String>{};
    String? cursor;

    for (var page = 0; page < _fallbackScanMaxPages; page++) {
      final url = cursor == null
          ? '${ApiEndpoints.productsWithDetails}?limit=$_fallbackScanPageSize'
          : '${ApiEndpoints.productsWithDetails}?limit=$_fallbackScanPageSize&cursor=${Uri.encodeQueryComponent(cursor)}';
      final response = await _apiService.get<dynamic>(url);
      if (!response.isSuccess) {
        return Result.failure(
          AppStrings.charityProfileLoadError,
          statusCode: response.statusCode,
        );
      }

      final rawProducts = _extractProducts(response.value);
      if (rawProducts == null) {
        return Result.failure(AppStrings.charityProfileLoadError);
      }

      for (final raw in rawProducts) {
        final parsed = _parseCharityProduct(
          raw,
          charityId: charity.id,
          fallbackCharity: charity,
        );
        if (parsed != null && seenIds.add(parsed.id)) {
          matched.add(parsed);
        }
      }

      final meta = _extractMeta(response.value);
      final hasMore = meta?['hasMore'] == true;
      final nextCursor = _text(meta?['nextCursor']);
      if (!hasMore || nextCursor == null || nextCursor == cursor) {
        break;
      }
      cursor = nextCursor;
    }

    return Result.success(
      CharityProfilePageData(
        charity: charity,
        products: List.unmodifiable(matched),
        nextCursor: null,
        hasMore: false,
      ),
    );
  }

  Result<CharityProfilePageData> _parseProductsPage({
    required Charity charity,
    required dynamic response,
    required String? requestedCursor,
  }) {
    final rawProducts = _extractProducts(response);
    if (rawProducts == null) {
      return Result.failure(AppStrings.charityProfileLoadError);
    }

    final meta = _extractMeta(response);
    final rawLimit = meta?['limit'];
    if (rawLimit != null && (rawLimit is! int || rawLimit < 1 || rawLimit > 50)) {
      return Result.failure(AppStrings.charityProfileLoadError);
    }
    final rawHasMore = meta?['hasMore'];
    final rawCursor = meta?['nextCursor'];
    if ((rawHasMore != null && rawHasMore is! bool) ||
        (rawCursor != null && rawCursor is! String)) {
      return Result.failure(AppStrings.charityProfileLoadError);
    }

    final nextCursor = _text(rawCursor);
    final hasMore = rawHasMore == true;
    if ((hasMore && (nextCursor == null || nextCursor == requestedCursor)) ||
        (!hasMore && nextCursor != null)) {
      return Result.failure(AppStrings.charityProfileLoadError);
    }

    final products = <Product>[];
    final seenIds = <String>{};
    for (final rawProduct in rawProducts) {
      final product = _parseCharityProduct(
        rawProduct,
        charityId: charity.id,
        fallbackCharity: charity,
      );
      if (product != null && seenIds.add(product.id)) {
        products.add(product);
      }
    }

    return Result.success(
      CharityProfilePageData(
        charity: charity,
        products: List.unmodifiable(products),
        nextCursor: nextCursor,
        hasMore: hasMore,
      ),
    );
  }

  static String resolveDescription(
    Charity? charity, {
    String? fallbackName,
  }) {
    final supplied = charity?.description?.trim();
    if (supplied != null && supplied.isNotEmpty) {
      return supplied;
    }
    final candidateNames = <String>[
      if (charity?.name.trim().isNotEmpty == true) charity!.name.trim(),
      if (fallbackName?.trim().isNotEmpty == true) fallbackName!.trim(),
    ];
    final discoverRepository = DiscoverRepository();
    for (final name in candidateNames) {
      final fallback = discoverRepository.descriptionForCharityName(name);
      if (fallback != null && fallback.trim().isNotEmpty) {
        return fallback.trim();
      }
    }
    return AppStrings.charityProfileNoDescription;
  }

  Charity? _extractCharityFromSingleResponse(
    dynamic response, {
    required String expectedId,
  }) {
    if (response is! Map) return null;
    if (response['success'] == false) return null;
    final payload = response['data'] is Map ? response['data'] : response;
    final charity = _parseCharity(payload);
    if (charity == null || charity.id != expectedId) {
      return null;
    }
    return charity;
  }

  List<dynamic> _extractCharityList(dynamic response) {
    if (response is List) return response;
    if (response is! Map) return const [];
    final data = response['data'];
    if (data is List) return data;
    if (data is Map && data['charities'] is List) {
      return data['charities'] as List;
    }
    if (response['charities'] is List) return response['charities'] as List;
    return const [];
  }

  List<dynamic>? _extractProducts(dynamic response) {
    if (response is List) return response;
    if (response is! Map) return null;
    if (response['success'] == false) return null;
    final data = response['data'];
    if (data is List) return data;
    if (data is Map && data['products'] is List) {
      return data['products'] as List;
    }
    if (response['products'] is List) return response['products'] as List;
    return null;
  }

  Map<dynamic, dynamic>? _extractMeta(dynamic response) {
    if (response is! Map) return null;
    final data = response['data'];
    final meta = response['meta'] ?? (data is Map ? data['meta'] : null);
    return meta is Map ? meta : null;
  }

  Product? _parseCharityProduct(
    dynamic value, {
    required String charityId,
    required Charity fallbackCharity,
  }) {
    if (value is! Map) return null;
    final status = _text(value['status']);
    final productCharityId = _identifier(
      value['charityId'] ?? value['charity_id'],
    );
    if ((status != null && status != 'active') ||
        productCharityId != charityId) {
      return null;
    }

    final id = _identifier(value['id'] ?? value['_id']);
    final userId = _identifier(value['userId'] ?? value['user_id']);
    final name = _text(value['name']);
    final description = value['description'];
    final quality = _text(value['quality']);
    final size = _text(value['size']);
    final postageSizeId = _identifier(
      value['postageSize'] ?? value['postageSizeId'] ?? value['postage_size_id'],
    );
    final price = _nonNegativeNumber(value['price']);
    final donation = _nonNegativeNumber(value['donation']);
    final securityFee = _nonNegativeNumber(value['securityFee']);
    final likes = _nonNegativeInteger(value['likes']);
    final number = _nonNegativeInteger(value['number']);
    final rawImages = value['product_images'] ?? value['images'];

    if (id == null ||
        userId == null ||
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

    final images = rawImages
        .map(_imageLocation)
        .whereType<String>()
        .toList(growable: false);

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
      categoryId: _identifier(value['categoryId'] ?? value['category_id']),
      charityId: productCharityId,
      createdAt: _text(value['createdAt']),
      updatedAt: _text(value['updatedAt']),
      category: _parseCategory(value['category']),
      charity: _parseCharity(value['charity']) ?? fallbackCharity,
    );
  }

  Category? _parseCategory(dynamic value) {
    if (value is! Map) return null;
    final id = _identifier(value['id']);
    final name = _text(value['name']);
    if (id == null || name == null) return null;
    return Category(
      id: id,
      name: name,
      imageUrl: _imageLocation(value['imageUrl'] ?? value['image_url']) ?? '',
      createdAt: _parseTimestamp(value['createdAt']),
      updatedAt: _parseTimestamp(value['updatedAt']),
    );
  }

  Charity? _parseCharity(dynamic value) {
    if (value is! Map) return null;
    final id = _identifier(value['id'] ?? value['_id']);
    final name = _text(value['name']);
    if (id == null || name == null) return null;
    final imageUrl = _imageLocation(value['imageUrl'] ?? value['image_url']) ?? '';
    return Charity(
      id: id,
      name: name,
      imageUrl: imageUrl,
      description: _text(value['description']),
      website: _httpUrl(value['website']),
      createdAt: _parseTimestamp(value['createdAt']),
      updatedAt: _parseTimestamp(value['updatedAt']),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (value is Map && value['_seconds'] is num) {
      final seconds = (value['_seconds'] as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static String _normalizeName(String value) =>
      DiscoverRepository.normalizeCharityName(value);

  static String? _text(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _identifier(dynamic value) =>
      CharityProfileArgs.safeIdentifier(_text(value));

  static String? _httpUrl(dynamic value) {
    final text = _text(value);
    final uri = text == null ? null : Uri.tryParse(text);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return text;
  }

  static String? _imageLocation(dynamic value) {
    final text = _text(value);
    if (text == null) return null;
    if (text.startsWith('assets/')) return text;
    return _httpUrl(text);
  }

  static double? _nonNegativeNumber(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : (value is String ? double.tryParse(value) : null);
    return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : null;
  }

  static int? _nonNegativeInteger(dynamic value) {
    final parsed = value is int
        ? value
        : (value is String ? int.tryParse(value) : null);
    return parsed != null && parsed >= 0 ? parsed : null;
  }
}
