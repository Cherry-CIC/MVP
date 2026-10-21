import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  test('DELETE carries the owner token and preserves the 200 response', () async {
    final adapter = _Adapter(
      (_) async => _body(200, {
        'success': true,
        'data': null,
      }),
    );
    final service = _service(_Auth(_User('owner')), adapter);

    final result = await service.delete<dynamic>('/api/products/listing-1');

    expect(result.isSuccess, isTrue);
    expect(result.statusCode, 200);
    expect(result.value, {'success': true, 'data': null});
    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer token');
  });

  for (final entry in {
    403: 'LISTING_NOT_OWNER',
    404: 'LISTING_NOT_FOUND',
    409: 'LISTING_REVIEW_REQUIRED',
  }.entries) {
    test('DELETE preserves ${entry.key} and ${entry.value}', () async {
      final adapter = _Adapter(
        (_) async => _body(entry.key, {
          'success': false,
          'code': entry.value,
          'message': 'PRIVATE_BACKEND_ERROR',
          'error': 'PRIVATE_BACKEND_ERROR',
        }),
      );

      final result = await _service(_Auth(_User('owner')), adapter).delete<dynamic>('/api/products/listing-1');

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, entry.key);
      expect(result.errorCode, entry.value);
      expect(result.error, isNot(contains('PRIVATE_BACKEND_ERROR')));
      expect(adapter.requests, hasLength(1));
    });
  }

  for (final code in [
    123,
    'a private backend message',
    'X' * 65,
  ]) {
    test('DELETE rejects unsafe error metadata $code', () async {
      final adapter = _Adapter(
        (_) async => _body(500, {
          'code': code,
          'error': {'code': 'LISTING_HAS_SALES'},
        }),
      );
      final result = await _service(_Auth(_User('owner')), adapter).delete<dynamic>('/api/products/listing-1');

      expect(result.statusCode, 500);
      expect(result.errorCode, isNull);
    });
  }

  for (final type in [
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  ]) {
    test('DELETE does not repeat a $type request', () async {
      final adapter = _Adapter((options) async {
        throw DioException(requestOptions: options, type: type);
      });
      final result = await _service(_Auth(_User('owner')), adapter).delete<dynamic>('/api/products/listing-1');

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, isNull);
      expect(adapter.requests, hasLength(1));
    });
  }

  test('DELETE with no authenticated owner never reaches the network', () async {
    final adapter = _Adapter((_) async => _body(200, {'success': true}));
    final result = await _service(_Auth(null), adapter).delete<dynamic>('/api/products/listing-1');

    expect(result.isSuccess, isFalse);
    expect(result.statusCode, 401);
    expect(result.errorCode, 'AUTHENTICATION_REQUIRED');
    expect(adapter.requests, isEmpty);
  });

  for (final token in [null, '   ']) {
    test('DELETE with unusable token "$token" never reaches the network', () async {
      final adapter = _Adapter((_) async => _body(200, {'success': true}));
      final result = await _service(
        _Auth(_User('owner', token: () async => token)),
        adapter,
      ).delete<dynamic>('/api/products/listing-1');

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, 401);
      expect(adapter.requests, isEmpty);
    });
  }

  test('DELETE fails closed if token retrieval fails', () async {
    final adapter = _Adapter((_) async => _body(200, {'success': true}));
    final result = await _service(
      _Auth(
        _User(
          'owner',
          token: () async {
            throw FirebaseAuthException(code: 'network-request-failed');
          },
        ),
      ),
      adapter,
    ).delete<dynamic>('/api/products/listing-1');

    expect(result.isSuccess, isFalse);
    expect(result.statusCode, 401);
    expect(adapter.requests, isEmpty);
  });

  test('DELETE fails closed if token retrieval times out', () async {
    final adapter = _Adapter((_) async => _body(200, {'success': true}));
    final result = await _service(
      _Auth(
        _User(
          'owner',
          token: () async {
            throw TimeoutException('PRIVATE_TOKEN_DETAILS');
          },
        ),
      ),
      adapter,
    ).delete<dynamic>('/api/products/listing-1');

    expect(result.isSuccess, isFalse);
    expect(result.statusCode, 401);
    expect(result.error, isNot(contains('PRIVATE_TOKEN_DETAILS')));
    expect(adapter.requests, isEmpty);
  });

  for (final nextUser in <User?>[null, _User('another-owner')]) {
    test('DELETE does not send when the account changes during token retrieval', () async {
      final token = Completer<String?>();
      final tokenRequested = Completer<void>();
      final auth = _Auth(
        _User(
          'owner',
          token: () {
            tokenRequested.complete();
            return token.future;
          },
        ),
      );
      final adapter = _Adapter((_) async => _body(200, {'success': true}));
      final request = _service(auth, adapter).delete<dynamic>('/api/products/listing-1');
      await tokenRequested.future;
      auth.user = nextUser;
      token.complete('original-owner-token');

      final result = await request;

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, 401);
      expect(adapter.requests, isEmpty);
    });
  }

  test('DELETE does not adopt a new account before the interceptor starts', () async {
    final auth = _Auth(_User('owner'));
    final adapter = _Adapter((_) async => _body(200, {'success': true}));
    final request = _service(auth, adapter).delete<dynamic>('/api/products/listing-1');
    auth.user = _User('another-owner');

    final result = await request;

    expect(result.isSuccess, isFalse);
    expect(result.statusCode, 401);
    expect(adapter.requests, isEmpty);
  });

  test('GET retains status and a safe top-level code for refresh decisions', () async {
    final adapter = _Adapter(
      (_) async => _body(403, {
        'code': 'LISTING_NOT_OWNER',
        'message': 'PRIVATE_BACKEND_ERROR',
      }),
    );
    final result = await _service(_Auth(null), adapter).get<dynamic>('/api/products/listing-1/with-details');

    expect(result.statusCode, 403);
    expect(result.errorCode, 'LISTING_NOT_OWNER');
    expect(result.error, isNot(contains('PRIVATE_BACKEND_ERROR')));
  });
}

DioApiService _service(FirebaseAuth auth, _Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
  return DioApiService.forTesting(auth, dio: dio, safeHttpLogSink: (_) {});
}

ResponseBody _body(int status, Object value) => ResponseBody.fromString(
  jsonEncode(value),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

class _Auth extends Mock implements FirebaseAuth {
  _Auth(this.user);
  User? user;
  @override
  User? get currentUser => user;
}

class _User extends Mock implements User {
  _User(this.uid, {Future<String?> Function()? token}) : _token = token ?? (() async => 'token');

  @override
  final String uid;
  final Future<String?> Function() _token;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) => _token();
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}
