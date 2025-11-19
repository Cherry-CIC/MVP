
import 'package:dio/dio.dart';

import 'package:cherry_mvp/core/models/donation_charity_model.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/services/error_string.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:logging/logging.dart';


abstract class ApiService {
  Future<Result<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters});
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
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    // Auth interceptor - add Firebase token to requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = _firebaseAuth.currentUser;
        if (user != null) {
          try {
            final idToken = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $idToken';
          } catch (e) {
            _log.severe('Error getting Firebase ID token: $e');
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Handle unauthorized access - could refresh token here
          _log.warning('Unauthorized access - user might need to re-authenticate');
        }
        
        // Check if we should retry the request
        if (_shouldRetry(error)) {
          try {
            await Future.delayed(const Duration(seconds: 1));
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } catch (e) {
            // If retry fails, proceed with original error
          }
        }
        handler.next(error);
      },
    ));

    // Logging interceptor
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      compact: true,
      maxWidth: 90,
    ));
  }
  
  @override
  Future<Result<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParameters);
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      _log.severe('GET request failed for $endpoint: ${e.toString()}');
      return Result.failure(_handleDioError(e));
    } catch (e) {
      _log.severe('Unexpected error in GET $endpoint: ${e.toString()}');
      return Result.failure(ErrorStrings.friendlyError);
    }
  }
  
  @override
  Future<Result<T>> post<T>(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      _log.severe('POST request failed for $endpoint: ${e.toString()}');
      return Result.failure(_handleDioError(e));
    } catch (e) {
      _log.severe('Unexpected error in POST $endpoint: ${e.toString()}');
      return Result.failure(ErrorStrings.friendlyError);
    }
  }
  
  @override
  Future<Result<T>> put<T>(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      _log.severe('PUT request failed for $endpoint: ${e.toString()}');
      return Result.failure(_handleDioError(e));
    } catch (e) {
      _log.severe('Unexpected error in PUT $endpoint: ${e.toString()}');
      return Result.failure(ErrorStrings.friendlyError);
    }
  }
  
  @override
  Future<Result<T>> delete<T>(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      _log.severe('DELETE request failed for $endpoint: ${e.toString()}');
      return Result.failure(_handleDioError(e));
    } catch (e) {
      _log.severe('Unexpected error in DELETE $endpoint: ${e.toString()}');
      return Result.failure(ErrorStrings.friendlyError);
    }
  }

  Result<T> _handleResponse<T>(Response response) {
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      return Result.success(response.data as T);
    } else {
      return Result.failure('Server returned status code: ${response.statusCode}');
    }
  }
  /// Fetch charity categories from the API.

  Future<Result<List<CharityCategories>>> git() async {
    const String endpoint = '/api/charities';

    final result = await get<Map<String, dynamic>>(endpoint);
    if (result.isSuccess && result.value != null) {
      try {
        final responseMap = result.value!;

        // Check if the response has a 'data' field
        if (!responseMap.containsKey('data')) {
          _log.severe('API response missing "data" field: $responseMap');
          return Result.failure('Invalid API response structure');
        }

        final charityListData = responseMap['data'];

        if (charityListData is! List) {
          _log.severe('Expected "data" to be a List but got ${charityListData.runtimeType}');
          return Result.failure('Invalid charity data format');
        }

        final charities = (charityListData as List<dynamic>)
            .map((json) => CharityCategories.fromJson(json as Map<String, dynamic>))
            .toList();

        _log.info('Successfully parsed ${charities.length} charities');
        return Result.success(charities);
      } catch (e) {
        _log.severe('Error parsing charity list: $e');
        return Result.failure('Failed to parse charity data: ${e.toString()}');
      }
    } else {
      return Result.failure(result.error ?? 'Unknown error occurred');
    }
  }
  String _handleDioError(DioException e) {
    // Log the technical details for debugging
    _log.warning('DioException occurred: ${e.type} - ${e.message}');
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ErrorStrings.timeoutError;
      case DioExceptionType.badCertificate:
        _log.severe('Bad certificate error: ${e.message}');
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
    
    // Log technical details for debugging
    _log.warning('Bad response: $statusCode - $data');
    
    switch (statusCode) {
      case 400:
      case 422:
        // Log specific validation errors for debugging
        final serverMessage = _extractErrorMessage(data);
        if (serverMessage != null) {
          _log.info('Server validation error: $serverMessage');
        }
        return ErrorStrings.apiError;
      case 401:
        return ErrorStrings.unauthorizedError;
      case 403:
      case 404:
        return ErrorStrings.apiError;
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

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError;
  }
}