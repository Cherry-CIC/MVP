import 'dart:async';
import 'package:dio/dio.dart';
import 'package:cherry_mvp/core/services/error_string.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

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
  static const String _defaultApiBaseUrl =
      'https://cherry-backend-401854471349.europe-west2.run.app';

  late final Dio _dio;
  final FirebaseAuth _firebaseAuth;
  final _log = Logger('DioApiService');

  DioApiService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    // Simple resolution: use .env if it exists, otherwise use default
    final baseUrl = dotenv.env['API_BASE_URL'] ?? _defaultApiBaseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: _stripTrailingSlash(baseUrl),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _log.info('API initialized with base URL: ${_dio.options.baseUrl}');
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final user = _firebaseAuth.currentUser;
            if (user != null) {
              // Get token with a short timeout to prevent "infinite loading" if Firebase hangs
              final idToken = await user.getIdToken().timeout(
                const Duration(seconds: 3),
                onTimeout: () {
                  _log.warning(
                    'Firebase token fetch timed out, proceeding without auth header',
                  );
                  return '';
                },
              );

              if (idToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $idToken';
              }
            }
          } catch (e) {
            _log.warning('Error attaching auth token: $e');
          }
          return handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
      ),
    );
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
      );
      return Result.success(response.data as T);
    } on DioException catch (e) {
      _log.severe('GET $endpoint failed: ${e.message}');
      return Result.failure(_handleDioError(e));
    }
  }

  @override
  Future<Result<T>> post<T>(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    }
  }

  @override
  Future<Result<T>> put<T>(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    }
  }

  @override
  Future<Result<T>> delete<T>(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    }
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ErrorStrings.timeoutError;
    }
    if (e.type == DioExceptionType.connectionError) {
      return ErrorStrings.networkError;
    }

    final statusCode = e.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return ErrorStrings.unauthorizedError;
    }
    if (statusCode != null && statusCode >= 500) {
      return ErrorStrings.serverError;
    }

    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
      final error = responseData['error']?.toString();
      if (error != null && error.trim().isNotEmpty) {
        return error.trim();
      }
    }

    return ErrorStrings.networkError;
  }

  String _stripTrailingSlash(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
