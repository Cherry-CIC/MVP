import 'dart:async';
import 'package:cherry_mvp/core/config/environment_config.dart';
import 'package:dio/dio.dart';
import 'package:cherry_mvp/core/services/error_string.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late final Dio _dio;
  final FirebaseAuth _firebaseAuth;
  final _log = Logger('DioApiService');

  DioApiService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
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

    _log.info('API initialised with base URL: ${_dio.options.baseUrl}');
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final user = _firebaseAuth.currentUser;
            if (user != null) {
              final idToken = await user.getIdToken().timeout(
                const Duration(seconds: 3),
                onTimeout: () => '',
              );

              if (idToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $idToken';
              }
            }
          } catch (e) {
            _log.warning('Auth interceptor error: $e');
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
      return Result.failure(_handleDioError(e));
    } catch (e) {
      _log.severe('Unexpected error in GET $endpoint: $e');
      return Result.failure(ErrorStrings.friendlyError);
    }
  }

  @override
  Future<Result<T>> post<T>(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (e) {
      _log.severe('Unexpected error in POST $endpoint: $e');
      return Result.failure(ErrorStrings.friendlyError);
    }
  }

  @override
  Future<Result<T>> put<T>(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (e) {
      _log.severe('Unexpected error in PUT $endpoint: $e');
      return Result.failure(ErrorStrings.friendlyError);
    }
  }

  @override
  Future<Result<T>> delete<T>(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (e) {
      _log.severe('Unexpected error in DELETE $endpoint: $e');
      return Result.failure(ErrorStrings.friendlyError);
    }
  }

  String _handleDioError(DioException e) {
    _log.warning('DioException occurred: ${e.type} - ${e.message}');

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
    final data = e.response?.data;

    _log.warning('Bad response: $statusCode - $data');

    switch (statusCode) {
      case 400:
      case 403:
      case 404:
      case 422:
      case 429:
        final serverMessage = _extractErrorMessage(data);
        if (serverMessage != null) {
          _log.info('Server validation error: $serverMessage');
        }
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

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] ?? data['error'] ?? data['detail'];
    }
    return null;
  }
}
