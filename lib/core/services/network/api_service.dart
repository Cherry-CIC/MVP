import 'dart:async';
import 'package:cherry_mvp/core/config/environment_config.dart';
import 'package:cherry_mvp/core/services/network/safe_http_log_interceptor.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:dio/dio.dart';
import 'package:cherry_mvp/core/services/error_string.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract class ApiService {
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  });
  Future<Result<T>> post<T>(String endpoint, {dynamic data});
  Future<Result<T>> put<T>(String endpoint, {dynamic data});
  Future<Result<T>> delete<T>(String endpoint);
}

class DioApiService implements ApiService {
  static const Duration _authTokenTimeout = Duration(seconds: 8);
  static const int _maxRetryAttempts = 1;
  static const String _retryAttemptKey = 'retry_attempt';

  late final Dio _dio;
  final FirebaseAuth _firebaseAuth;

  DioApiService({FirebaseAuth? firebaseAuth}) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    final baseUrl = AppEnvironment.apiBaseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    SafeLog.event(AppLogEvent.apiInitialised);
    _setupInterceptors();
  }

  @visibleForTesting
  DioApiService.forTesting(
    this._firebaseAuth, {
    required Dio dio,
    SafeHttpLogSink? safeHttpLogSink,
  }) {
    _dio = dio;
    _setupInterceptors(safeHttpLogSink: safeHttpLogSink);
  }

  void _setupInterceptors({SafeHttpLogSink? safeHttpLogSink}) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            await _attachAuthHeader(options);
          } on TimeoutException {
            SafeLog.event(
              AppLogEvent.authTokenTimeout,
              level: SafeLogLevel.severe,
            );
          } on FirebaseAuthException {
            SafeLog.event(
              AppLogEvent.authTokenFirebaseFailure,
              level: SafeLogLevel.severe,
            );
          } catch (_) {
            SafeLog.event(
              AppLogEvent.authTokenUnexpectedFailure,
              level: SafeLogLevel.warning,
            );
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            SafeLog.event(
              AppLogEvent.unauthorisedRequest,
              level: SafeLogLevel.warning,
            );
          }

          final retryResponse = await _retryRequestIfSafe(error);
          if (retryResponse != null) {
            return handler.resolve(retryResponse);
          }

          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        SafeHttpLogInterceptor(sink: safeHttpLogSink),
      );
    }
  }

  @override
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: _safeOptions('GET', endpoint),
      );
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (_) {
      SafeLog.event(
        AppLogEvent.unexpectedGetFailure,
        level: SafeLogLevel.severe,
      );
      return Result.failure(ErrorStrings.friendlyError);
    }
  }

  @override
  Future<Result<T>> post<T>(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: _safeOptions('POST', endpoint),
      );
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (_) {
      SafeLog.event(
        AppLogEvent.unexpectedPostFailure,
        level: SafeLogLevel.severe,
      );
      return Result.failure(ErrorStrings.friendlyError);
    }
  }

  @override
  Future<Result<T>> put<T>(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        options: _safeOptions('PUT', endpoint),
      );
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (_) {
      SafeLog.event(
        AppLogEvent.unexpectedPutFailure,
        level: SafeLogLevel.severe,
      );
      return Result.failure(ErrorStrings.friendlyError);
    }
  }

  @override
  Future<Result<T>> delete<T>(String endpoint) async {
    try {
      final response = await _dio.delete(
        endpoint,
        options: _safeOptions('DELETE', endpoint),
      );
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (_) {
      SafeLog.event(
        AppLogEvent.unexpectedDeleteFailure,
        level: SafeLogLevel.severe,
      );
      return Result.failure(ErrorStrings.friendlyError);
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ErrorStrings.timeoutError;
      case DioExceptionType.badCertificate:
        return ErrorStrings.serverError;
      case DioExceptionType.cancel:
        return ErrorStrings.friendlyError;
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return ErrorStrings.networkError;
      case DioExceptionType.badResponse:
        return _handleBadResponse(e);
    }
  }

  String _handleBadResponse(DioException e) {
    final statusCode = e.response?.statusCode;

    switch (statusCode) {
      case 400:
      case 403:
      case 404:
      case 422:
      case 429:
        return ErrorStrings.apiError;
      case 401:
        return ErrorStrings.unauthorizedError;
      case 500:
      case 502:
      case 503:
        return ErrorStrings.serverError;
      default:
        return ErrorStrings.friendlyError;
    }
  }

  Future<void> _attachAuthHeader(RequestOptions options) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }

    final idToken = await user.getIdToken().timeout(_authTokenTimeout);
    final trimmedToken = (idToken ?? '').trim();

    if (trimmedToken.isEmpty) {
      throw StateError('Firebase returned an empty ID token.');
    }

    options.headers['Authorization'] = 'Bearer $trimmedToken';
  }

  Future<Response<dynamic>?> _retryRequestIfSafe(DioException error) async {
    if (!_shouldRetry(error)) {
      return null;
    }

    final requestOptions = error.requestOptions;
    if (!_isRetryableMethod(requestOptions.method)) {
      return null;
    }

    final attempt = (requestOptions.extra[_retryAttemptKey] as int?) ?? 0;
    if (attempt >= _maxRetryAttempts) {
      return null;
    }

    requestOptions.extra[_retryAttemptKey] = attempt + 1;
    SafeLog.event(AppLogEvent.networkRetryStarted);

    try {
      return await _dio.fetch<dynamic>(requestOptions);
    } on DioException {
      SafeLog.event(
        AppLogEvent.networkRetryFailed,
        level: SafeLogLevel.warning,
      );
      return null;
    }
  }

  bool _shouldRetry(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return false;
    }
  }

  bool _isRetryableMethod(String method) {
    return method.toUpperCase() == 'GET';
  }

  Options _safeOptions(String method, String endpoint) {
    return Options(
      extra: <String, Object>{
        SafeHttpLogInterceptor.operationExtraKey: classifyHttpOperation(
          method: method,
          endpoint: endpoint,
        ),
      },
    );
  }
}
