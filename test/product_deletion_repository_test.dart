import 'dart:async';

import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deletion accepts HTTP 200 with success:true and data:null', () async {
    final api = _Api(
      deletion: Result.success(
        {'success': true, 'data': null},
        statusCode: 200,
      ),
    );
    final deleted = DeletedListings();
    final repository = ProductRepository(api, deletedListings: deleted);

    final result = await repository.deleteProduct('listing-1');

    expect(result.isSuccess, isTrue);
    expect(result.statusCode, 200);
    expect(api.deleteEndpoint, ApiEndpoints.productById('listing-1'));
    expect(api.deleteCalls, 1);
    // Only the account-aware caller may record a confirmed deletion.
    expect(deleted.contains('listing-1'), isFalse);
  });

  for (final status in <int?>[null, 201, 202, 204]) {
    test('deletion does not accept HTTP $status as a confirmed deletion', () async {
      final repository = ProductRepository(
        _Api(
          deletion: Result.success({'success': true}, statusCode: status),
        ),
      );

      final result = await repository.deleteProduct('listing-1');

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, status);
    });
  }

  for (final response in [
    null,
    '',
    <dynamic>[],
    <String, dynamic>{},
    {'success': false, 'message': 'PRIVATE_BACKEND_ERROR'},
    {'success': 'true'},
    {'data': null},
  ]) {
    test('deletion rejects an unconfirmed envelope $response', () async {
      final repository = ProductRepository(
        _Api(
          deletion: Result.success(response, statusCode: 200),
        ),
      );

      final result = await repository.deleteProduct('listing-1');

      expect(result.isSuccess, isFalse);
      expect(result.error, isNot(contains('PRIVATE_BACKEND_ERROR')));
    });
  }

  for (final code in [
    'LISTING_NOT_OWNER',
    'LISTING_NOT_FOUND',
    'LISTING_PAYMENT_PENDING',
    'LISTING_HAS_SALES',
    'LISTING_REVIEW_REQUIRED',
    'UNRECOGNISED_CONFLICT',
  ]) {
    test('deletion forwards structured $code without backend message text', () async {
      final status = switch (code) {
        'LISTING_NOT_OWNER' => 403,
        'LISTING_NOT_FOUND' => 404,
        _ => 409,
      };
      final api = _Api(
        deletion: Result.failure(
          'PRIVATE_BACKEND_ERROR',
          statusCode: status,
          errorCode: code,
        ),
      );
      final result = await ProductRepository(api).deleteProduct('listing-1');

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, status);
      expect(result.errorCode, code);
      expect(result.error, isNot(contains('PRIVATE_BACKEND_ERROR')));
      expect(api.deleteCalls, 1);
    });
  }

  test('deletion does not retry an uncertain transport failure', () async {
    final api = _Api(deletion: Result.failure('Request timed out.'));

    final result = await ProductRepository(api).deleteProduct('listing-1');

    expect(result.isSuccess, isFalse);
    expect(result.statusCode, isNull);
    expect(api.deleteCalls, 1);
  });

  test('deletion handles a thrown API error without retry or leaked details', () async {
    final api = _Api(deleteException: StateError('PRIVATE_REQUEST_DETAILS'));

    final result = await ProductRepository(api).deleteProduct('listing-1');

    expect(result.isSuccess, isFalse);
    expect(result.error, isNot(contains('PRIVATE_REQUEST_DETAILS')));
    expect(api.deleteCalls, 1);
  });

  for (final id in ['', ' ', 'invalid/id']) {
    test('deletion validates "$id" before requesting', () async {
      final api = _Api();

      final result = await ProductRepository(api).deleteProduct(id);

      expect(result.isSuccess, isFalse);
      expect(api.deleteCalls, 0);
    });
  }

  test('detail refresh preserves structured status and code', () async {
    final repository = ProductRepository(
      _Api(
        detail: Future.value(
          Result.failure(
            'Unable to load this listing.',
            statusCode: 403,
            errorCode: 'LISTING_NOT_OWNER',
          ),
        ),
      ),
    );

    final result = await repository.fetchProduct('listing-1');

    expect(result.isSuccess, isFalse);
    expect(result.statusCode, 403);
    expect(result.errorCode, 'LISTING_NOT_OWNER');
  });

  test('a confirmed deletion blocks later detail requests', () async {
    final api = _Api();
    final deleted = DeletedListings()..add('listing-1');
    final repository = ProductRepository(api, deletedListings: deleted);

    final result = await repository.fetchProduct('listing-1');

    expect(result.isSuccess, isFalse);
    expect(result.statusCode, 404);
    expect(result.errorCode, 'LISTING_NOT_FOUND');
    expect(api.getCalls, 0);
  });

  test('a detail response started before deletion cannot restore the listing', () async {
    final response = Completer<Result<dynamic>>();
    final api = _Api(detail: response.future);
    final deleted = DeletedListings();
    final repository = ProductRepository(api, deletedListings: deleted);
    final pending = repository.fetchProduct('listing-1');

    deleted.add('listing-1');
    response.complete(
      Result.success({
        'success': true,
        'data': {
          'id': 'listing-1',
          'userId': 'owner',
          'name': 'Blue jacket',
          'description': '',
          'quality': 'GOOD',
          'product_images': <String>[],
          'donation': 7,
          'price': 7,
          'securityFee': 1,
          'likes': 0,
          'number': 1,
          'size': 'M',
          'postageSize': 'small',
        },
      }),
    );

    final result = await pending;

    expect(result.isSuccess, isFalse);
    expect(result.statusCode, 404);
    expect(result.errorCode, 'LISTING_NOT_FOUND');
    expect(api.getCalls, 1);
  });
}

class _Api implements ApiService {
  _Api({this.deletion, this.detail, this.deleteException});
  final Result<dynamic>? deletion;
  final Future<Result<dynamic>>? detail;
  final Object? deleteException;
  int deleteCalls = 0;
  int getCalls = 0;
  String? deleteEndpoint;

  @override
  Future<Result<T>> delete<T>(String endpoint) async {
    deleteCalls++;
    deleteEndpoint = endpoint;
    if (deleteException != null) throw deleteException!;
    final result = deletion ?? Result.failure('Unexpected deletion.');
    return result.isSuccess
        ? Result.success(result.value as T, statusCode: result.statusCode)
        : Result.failure(
            result.error,
            statusCode: result.statusCode,
            errorCode: result.errorCode,
          );
  }

  @override
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    getCalls++;
    final result = await (detail ?? Future.value(Result<dynamic>.failure('Unexpected detail request.')));
    return result.isSuccess
        ? Result.success(result.value as T, statusCode: result.statusCode)
        : Result.failure(
            result.error,
            statusCode: result.statusCode,
            errorCode: result.errorCode,
          );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
