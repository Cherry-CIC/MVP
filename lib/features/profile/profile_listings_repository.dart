import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:logging/logging.dart';

abstract class IProfileListingsRepository {
  Future<Result<ProfileListingsPage>> fetchListings({
    int limit = 20,
    String? cursor,
  });
}

class ProfileListingsPage {
  final List<SellerListing> listings;
  final int limit;
  final String? nextCursor;
  final bool hasMore;

  const ProfileListingsPage({
    required this.listings,
    required this.limit,
    required this.nextCursor,
    required this.hasMore,
  });
}

class ProfileListingsRepository implements IProfileListingsRepository {
  final ApiService _apiService;
  final _log = Logger('ProfileListingsRepository');

  ProfileListingsRepository(this._apiService);

  @override
  Future<Result<ProfileListingsPage>> fetchListings({
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final result = await _apiService.get<dynamic>(
        ApiEndpoints.myProducts,
        queryParameters: {
          'limit': limit,
          if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
        },
      );

      if (!result.isSuccess || result.value == null) {
        return Result.failure(
          result.error ?? 'Could not load your listings',
        );
      }

      final response = result.value;
      if (response is Map && response['success'] == false) {
        return Result.failure('Could not load your listings');
      }

      final rawListings = _extractListings(response);
      if (rawListings == null) {
        _log.warning(
          'Unexpected profile listings response: ${response.runtimeType}',
        );
        return Result.failure('Unexpected listings response');
      }

      final listings = rawListings.map(SellerListing.tryFromJson).whereType<SellerListing>().toList(growable: false);
      final meta = _extractMeta(response);

      return Result.success(
        ProfileListingsPage(
          listings: listings,
          limit: meta.limit ?? limit,
          nextCursor: meta.nextCursor,
          hasMore: meta.hasMore,
        ),
      );
    } catch (error) {
      _log.severe('Profile listings request failed: $error');
      return Result.failure('Could not load your listings');
    }
  }

  List<dynamic>? _extractListings(dynamic response) {
    if (response is List) {
      return response;
    }

    if (response is Map) {
      final data = response['data'];
      if (data is List) {
        return data;
      }
      if (data is Map && data['products'] is List) {
        return data['products'] as List;
      }
      if (response['products'] is List) {
        return response['products'] as List;
      }
    }

    return null;
  }

  _ProfileListingsMeta _extractMeta(dynamic response) {
    if (response is! Map) {
      return const _ProfileListingsMeta();
    }

    final data = response['data'];
    final rawMeta = response['meta'] ?? (data is Map ? data['meta'] : null);
    if (rawMeta is! Map) {
      return const _ProfileListingsMeta();
    }

    return _ProfileListingsMeta(
      limit: _parseInt(rawMeta['limit']),
      nextCursor: rawMeta['nextCursor'] is String ? rawMeta['nextCursor'] as String : null,
      hasMore: rawMeta['hasMore'] == true,
    );
  }

  int? _parseInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

class _ProfileListingsMeta {
  final int? limit;
  final String? nextCursor;
  final bool hasMore;

  const _ProfileListingsMeta({
    this.limit,
    this.nextCursor,
    this.hasMore = false,
  });
}
