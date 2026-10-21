import 'dart:typed_data';

import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  test('Result constructors remain compatible and success has no error status', () {
    expect(Result.success('value').statusCode, isNull);
    expect(Result.failure('error').statusCode, isNull);
    final result = Result<String>.failure('error', statusCode: 410);
    expect(result.statusCode, 410);
    expect(result.value, isNull);
    expect(result.isSuccess, isFalse);
  });

  for (final status in [404, 410, 403, 500]) {
    test('GET preserves HTTP $status using safe error copy', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = _StatusAdapter(status);
      final service = DioApiService.forTesting(_AuthWithoutUser(), dio: dio, safeHttpLogSink: (_) {});

      final result = await service.get<dynamic>('/api/users/seller/profile');

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, status);
      expect(result.error, isNot(contains('PRIVATE_BACKEND_ERROR')));
    });
  }
}

class _AuthWithoutUser extends Mock implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status);
  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"error":"PRIVATE_BACKEND_ERROR"}',
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}
