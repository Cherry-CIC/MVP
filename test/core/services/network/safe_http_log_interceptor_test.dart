import 'dart:convert';

import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/services/network/safe_http_log_interceptor.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

const _secret = 'TEST_SECRET_MUST_NOT_APPEAR_7f3a';

void main() {
  group('HTTP operation classification', () {
    test('maps known endpoints to fixed operation names', () {
      final cases = <({String method, String endpoint, SafeHttpOperation expected})>[
        (
          method: 'GET',
          endpoint: '/api/products/with-details',
          expected: SafeHttpOperation.loadProducts,
        ),
        (
          method: 'GET',
          endpoint: '/api/products/my-products',
          expected: SafeHttpOperation.loadProfileListings,
        ),
        (
          method: 'GET',
          endpoint: '/api/products/my-liked-items',
          expected: SafeHttpOperation.loadLikedProducts,
        ),
        (
          method: 'GET',
          endpoint: '/api/auth/profile',
          expected: SafeHttpOperation.loadProfile,
        ),
        (
          method: 'POST',
          endpoint: '/api/products',
          expected: SafeHttpOperation.createDonation,
        ),
        (
          method: 'POST',
          endpoint: '/api/payment/create-payment-intent',
          expected: SafeHttpOperation.createPaymentIntent,
        ),
        (
          method: 'DELETE',
          endpoint: '/api/auth/account',
          expected: SafeHttpOperation.deleteAccount,
        ),
      ];

      for (final testCase in cases) {
        expect(
          classifyHttpOperation(
            method: testCase.method,
            endpoint: testCase.endpoint,
          ),
          testCase.expected,
        );
      }
    });

    test('replaces dynamic product identifiers with fixed operations', () {
      expect(
        classifyHttpOperation(
          method: 'GET',
          endpoint: '/api/products/$_secret?token=$_secret#$_secret',
        ),
        SafeHttpOperation.loadProduct,
      );
      expect(
        classifyHttpOperation(
          method: 'POST',
          endpoint: '/api/products/$_secret/like?token=$_secret',
        ),
        SafeHttpOperation.updateProductLike,
      );
    });

    test('uses a safe fallback for unknown or malformed endpoints', () {
      expect(
        classifyHttpOperation(
          method: 'GET',
          endpoint: '/api/private/$_secret?token=$_secret',
        ),
        SafeHttpOperation.unclassifiedRequest,
      );
      expect(
        classifyHttpOperation(method: 'GET', endpoint: '://$_secret'),
        SafeHttpOperation.unclassifiedRequest,
      );
    });
  });

  group('SafeHttpLogInterceptor', () {
    test('allows only approved metadata to reach the sink', () async {
      final records = <SafeHttpLogRecord>[];
      final adapter = _StubAdapter(
        (_) async => ResponseBody.fromString(
          '{"profile":{"email":"$_secret"}}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
            'set-cookie': ['session=$_secret'],
          },
        ),
      );
      final dio = _dioWith(adapter, records.add);

      await dio.post<dynamic>(
        'https://example.test/api/auth/profile?access_token=$_secret#$_secret',
        data: {
          'token': _secret,
          'nested': [
            {'email': 'person+$_secret@example.test'},
          ],
        },
        options: Options(
          headers: {
            'aUtHoRiZaTiOn': 'Bearer $_secret',
            'Cookie': 'session=$_secret',
          },
          extra: {
            SafeHttpLogInterceptor.operationExtraKey: SafeHttpOperation.loadProfile,
          },
        ),
      );

      expect(records, hasLength(1));
      final record = records.single;
      expect(
        record.approvedMetadata.keys,
        orderedEquals(['method', 'operation', 'status', 'duration_ms']),
      );
      expect(record.approvedMetadata['method'], 'POST');
      expect(record.approvedMetadata['operation'], 'load_profile');
      expect(record.approvedMetadata['status'], 200);
      expect(record.approvedMetadata['duration_ms'], isA<int>());
      _expectNoSensitiveData(record.toLogLine());
    });

    test('bearer tokens never appear in captured debug output', () async {
      final capturedOutput = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          capturedOutput.add(message);
        }
      };
      addTearDown(() => debugPrint = previousDebugPrint);

      final dio = Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = _StubAdapter(
          (_) async => ResponseBody.fromString('Bearer $_secret', 200),
        )
        ..interceptors.add(SafeHttpLogInterceptor());

      await dio.get<dynamic>(
        'https://example.test/api/auth/profile?token=$_secret',
        options: Options(
          headers: {'AUTHORIZATION': 'Bearer $_secret'},
          extra: {
            SafeHttpLogInterceptor.operationExtraKey: SafeHttpOperation.loadProfile,
          },
        ),
      );

      expect(capturedOutput, hasLength(1));
      expect(capturedOutput.single, startsWith('HTTP GET load_profile status=200'));
      _expectNoSensitiveData(capturedOutput.join('\n'));
    });

    test('does not expose nested error responses or raw exceptions', () async {
      final responseRecords = <SafeHttpLogRecord>[];
      final responseDio = _dioWith(
        _StubAdapter(
          (_) async => ResponseBody.fromString(
            '{"errors":[{"token":"$_secret"}]}',
            422,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
              'location': ['https://redirect.test/?token=$_secret'],
            },
          ),
        ),
        responseRecords.add,
      );

      await expectLater(
        responseDio.get<dynamic>(
          'https://example.test/api/orders?token=$_secret',
          options: Options(
            extra: {
              SafeHttpLogInterceptor.operationExtraKey: SafeHttpOperation.loadOrders,
            },
          ),
        ),
        throwsA(isA<DioException>()),
      );

      expect(responseRecords.single.statusCode, 422);
      expect(
        responseRecords.single.errorCategory,
        SafeHttpErrorCategory.httpResponse,
      );
      _expectNoSensitiveData(responseRecords.single.toLogLine());

      final exceptionRecords = <SafeHttpLogRecord>[];
      final exceptionDio = _dioWith(
        _StubAdapter(
          (options) => throw DioException(
            requestOptions: options,
            message: 'retry failed at https://$_secret.test/?token=$_secret',
            error: StateError(_secret),
            type: DioExceptionType.connectionError,
          ),
        ),
        exceptionRecords.add,
      );

      await expectLater(
        exceptionDio.get<dynamic>('https://example.test/unknown/$_secret'),
        throwsA(isA<DioException>()),
      );

      expect(
        exceptionRecords.single.operation,
        SafeHttpOperation.unclassifiedRequest,
      );
      expect(
        exceptionRecords.single.errorCategory,
        SafeHttpErrorCategory.connection,
      );
      _expectNoSensitiveData(exceptionRecords.single.toLogLine());
    });

    test('does not expose retry destinations or exceptions', () async {
      final capturedOutput = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          capturedOutput.add(message);
        }
      };
      addTearDown(() => debugPrint = previousDebugPrint);

      final adapter = _RetryFailureAdapter();
      final records = <SafeHttpLogRecord>[];
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.test',
          responseType: ResponseType.plain,
        ),
      )..httpClientAdapter = adapter;
      final service = DioApiService.forTesting(
        _FirebaseAuthWithoutUser(),
        dio: dio,
        safeHttpLogSink: records.add,
      );

      final result = await service.get<dynamic>(
        '/api/auth/profile?destination=https://$_secret.test&token=$_secret',
      );

      expect(result.isSuccess, isFalse);
      expect(adapter.attempts, 2);
      expect(
        capturedOutput,
        containsAll(<String>[
          'INFO event=network_retry_started',
          'WARNING event=network_retry_failed',
        ]),
      );
      expect(records, hasLength(2));
      for (final record in records) {
        _expectNoSensitiveData(record.toLogLine());
      }
      _expectNoSensitiveData(capturedOutput.join('\n'));
    });

    test('does not expose redirect destinations', () async {
      final records = <SafeHttpLogRecord>[];
      final dio = _dioWith(
        _StubAdapter(
          (_) async => ResponseBody(
            Stream.value(Uint8List.fromList(utf8.encode(_secret))),
            200,
            isRedirect: true,
            redirects: [
              RedirectRecord(
                302,
                'GET',
                Uri.parse('https://redirect.test/?token=$_secret'),
              ),
            ],
          ),
        ),
        records.add,
      );

      await dio.get<dynamic>('https://example.test/api/auth/profile');

      _expectNoSensitiveData(records.single.toLogLine());
    });

    test('does not expose multipart fields or filenames', () async {
      final records = <SafeHttpLogRecord>[];
      final dio = _dioWith(
        _StubAdapter(
          (_) async => ResponseBody.fromString('', 204),
        ),
        records.add,
      );
      final formData = FormData.fromMap({
        'token': _secret,
        'nested': {'secret': _secret},
        'file': MultipartFile.fromString(
          _secret,
          filename: 'private_$_secret.jpg',
        ),
      });

      await dio.post<dynamic>(
        'https://example.test/api/products?token=$_secret',
        data: formData,
        options: Options(
          extra: {
            SafeHttpLogInterceptor.operationExtraKey: SafeHttpOperation.createDonation,
          },
        ),
      );

      _expectNoSensitiveData(records.single.toLogLine());
    });

    test('a failing sink cannot alter the underlying request', () async {
      final adapter = _StubAdapter(
        (_) async => ResponseBody.fromString('request completed', 200),
      );
      final dio = _dioWith(adapter, (_) => throw StateError(_secret));

      final response = await dio.post<String>(
        'https://example.test/api/products?token=$_secret',
        data: {'token': _secret},
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Authorization': 'Bearer $_secret'},
          extra: {
            SafeHttpLogInterceptor.operationExtraKey: SafeHttpOperation.createDonation,
          },
        ),
      );

      expect(response.data, 'request completed');
      expect(adapter.lastRequest, isNotNull);
      expect(adapter.lastRequest!.uri.query, contains(_secret));
      expect(
        adapter.lastRequest!.headers['Authorization'],
        'Bearer $_secret',
      );
    });
  });
}

Dio _dioWith(HttpClientAdapter adapter, SafeHttpLogSink sink) {
  return Dio(
      BaseOptions(responseType: ResponseType.plain),
    )
    ..httpClientAdapter = adapter
    ..interceptors.add(SafeHttpLogInterceptor(sink: sink));
}

void _expectNoSensitiveData(String output) {
  expect(output, isNot(contains(_secret)));
  expect(output.toLowerCase(), isNot(contains('authorization')));
  expect(output.toLowerCase(), isNot(contains('cookie')));
  expect(output.toLowerCase(), isNot(contains('access_token')));
  expect(output.toLowerCase(), isNot(contains('redirect.test')));
  expect(output.toLowerCase(), isNot(contains('example.test')));
  expect(output.toLowerCase(), isNot(contains('filename')));
}

typedef _Responder = Future<ResponseBody> Function(RequestOptions options);

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._responder);

  final _Responder _responder;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    lastRequest = options;
    return _responder(options);
  }

  @override
  void close({bool force = false}) {}
}

class _RetryFailureAdapter implements HttpClientAdapter {
  int attempts = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    attempts++;
    throw DioException(
      requestOptions: options,
      message: 'Retry $attempts failed at https://$_secret.test/?token=$_secret',
      error: StateError(_secret),
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FirebaseAuthWithoutUser extends Mock implements FirebaseAuth {
  @override
  User? get currentUser => null;
}
