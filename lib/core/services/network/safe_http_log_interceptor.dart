import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:dio/dio.dart';

typedef SafeHttpLogSink = void Function(SafeHttpLogRecord record);

class SafeHttpLogInterceptor extends Interceptor {
  SafeHttpLogInterceptor({SafeHttpLogSink? sink}) : _sink = sink ?? SafeLog.http;

  static const String operationExtraKey = 'cherry.safe_http.operation';
  static const String _stopwatchExtraKey = 'cherry.safe_http.stopwatch';

  final SafeHttpLogSink _sink;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      options.extra[_stopwatchExtraKey] = Stopwatch()..start();
    } catch (_) {
      // Diagnostics must never change the request.
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    try {
      _sink(
        _recordFor(
          response.requestOptions,
          statusCode: response.statusCode,
        ),
      );
    } catch (_) {
      // Diagnostics must never change the response.
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      _sink(
        _recordFor(
          err.requestOptions,
          statusCode: err.response?.statusCode,
          errorCategory: _categoryFor(err.type),
        ),
      );
    } catch (_) {
      // Diagnostics must never change the error.
    }
    handler.next(err);
  }

  SafeHttpLogRecord _recordFor(
    RequestOptions options, {
    int? statusCode,
    SafeHttpErrorCategory? errorCategory,
  }) {
    final stopwatch = options.extra[_stopwatchExtraKey];
    final durationMs = switch (stopwatch) {
      Stopwatch stopwatch => _stopAndRead(stopwatch),
      _ => 0,
    };
    final operation = switch (options.extra[operationExtraKey]) {
      SafeHttpOperation operation => operation,
      _ => SafeHttpOperation.unclassifiedRequest,
    };

    return SafeHttpLogRecord(
      method: safeHttpMethod(options.method),
      operation: operation,
      statusCode: _safeStatusCode(statusCode),
      durationMs: durationMs,
      errorCategory: errorCategory,
    );
  }

  int _stopAndRead(Stopwatch stopwatch) {
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds;
  }

  int? _safeStatusCode(int? statusCode) {
    if (statusCode == null || statusCode < 100 || statusCode > 599) {
      return null;
    }
    return statusCode;
  }

  SafeHttpErrorCategory _categoryFor(DioExceptionType type) {
    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => SafeHttpErrorCategory.timeout,
      DioExceptionType.badCertificate => SafeHttpErrorCategory.badCertificate,
      DioExceptionType.cancel => SafeHttpErrorCategory.cancelled,
      DioExceptionType.connectionError => SafeHttpErrorCategory.connection,
      DioExceptionType.badResponse => SafeHttpErrorCategory.httpResponse,
      DioExceptionType.unknown => SafeHttpErrorCategory.unknown,
    };
  }
}

SafeHttpMethod safeHttpMethod(String method) {
  return switch (method.toUpperCase()) {
    'GET' => SafeHttpMethod.get,
    'POST' => SafeHttpMethod.post,
    'PUT' => SafeHttpMethod.put,
    'DELETE' => SafeHttpMethod.delete,
    'PATCH' => SafeHttpMethod.patch,
    'HEAD' => SafeHttpMethod.head,
    'OPTIONS' => SafeHttpMethod.options,
    _ => SafeHttpMethod.other,
  };
}

SafeHttpOperation classifyHttpOperation({
  required String method,
  required String endpoint,
}) {
  final path = Uri.tryParse(endpoint)?.path;
  if (path == null || path.isEmpty) {
    return SafeHttpOperation.unclassifiedRequest;
  }

  final normalisedMethod = method.toUpperCase();
  if (normalisedMethod == 'GET') {
    switch (path) {
      case ApiEndpoints.products:
      case ApiEndpoints.productsWithDetails:
        return SafeHttpOperation.loadProducts;
      case ApiEndpoints.myProducts:
        return SafeHttpOperation.loadProfileListings;
      case ApiEndpoints.likedProducts:
        return SafeHttpOperation.loadLikedProducts;
      case ApiEndpoints.categories:
        return SafeHttpOperation.loadCategories;
      case ApiEndpoints.inpostLockers:
        return SafeHttpOperation.findPickupPoints;
      case ApiEndpoints.inpostShippingMethods:
        return SafeHttpOperation.loadShippingMethods;
      case ApiEndpoints.charities:
        return SafeHttpOperation.loadCharities;
      case ApiEndpoints.postageSizes:
        return SafeHttpOperation.loadPostageSizes;
      case ApiEndpoints.myOrders:
        return SafeHttpOperation.loadOrders;
      case ApiEndpoints.profile:
        return SafeHttpOperation.loadProfile;
    }

    if (RegExp(r'^/api/products/[^/]+$').hasMatch(path)) {
      return SafeHttpOperation.loadProduct;
    }
  }

  if (normalisedMethod == 'POST') {
    switch (path) {
      case ApiEndpoints.products:
        return SafeHttpOperation.createDonation;
      case ApiEndpoints.authSync:
        return SafeHttpOperation.syncAuthentication;
      case ApiEndpoints.paymentIntent:
        return SafeHttpOperation.createPaymentIntent;
      case ApiEndpoints.createOrder:
        return SafeHttpOperation.createOrder;
    }

    if (RegExp(r'^/api/products/[^/]+/like$').hasMatch(path)) {
      return SafeHttpOperation.updateProductLike;
    }
  }

  if (normalisedMethod == 'DELETE' && path == ApiEndpoints.deleteAccount) {
    return SafeHttpOperation.deleteAccount;
  }

  return SafeHttpOperation.unclassifiedRequest;
}
