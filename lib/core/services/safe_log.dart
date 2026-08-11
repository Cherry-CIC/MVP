import 'package:flutter/foundation.dart';

enum AppLogEvent {
  addressApiKeyMissing,
  addressLoadFailed,
  addressLoadSkippedNoUser,
  addressLoadSucceeded,
  addressPlaceDetailsFailed,
  addressPlaceDetailsRejected,
  addressSaveFailed,
  addressSaveSkippedNoUser,
  addressSaveSucceeded,
  addressSearchFailed,
  addressSearchRejected,
  apiInitialised,
  authProviderInitialisationFailed,
  authenticationOperationFailed,
  authTokenFirebaseFailure,
  authTokenTimeout,
  authTokenUnexpectedFailure,
  categoryLoadFailed,
  charityLoadFailed,
  checkoutOrderCreationFailed,
  checkoutPaymentFailed,
  checkoutPaymentIntentFailed,
  checkoutPickupPointsFailed,
  checkoutProfileLoadFailed,
  checkoutProfileMissing,
  checkoutShippingMethodsFailed,
  donationImageUploadFailed,
  donationImageUploadStarted,
  donationImageUploadSucceeded,
  donationPostageSizesLoadFailed,
  donationSubmissionFailed,
  donationSubmissionStarted,
  donationSubmissionSucceeded,
  firebaseEmulatorsEnabled,
  homeProductParseFailed,
  homeProductsLoadFailed,
  homeProductsLoadStarted,
  homeProductsLoadSucceeded,
  homeProductsResponseInvalid,
  homeSearchFailed,
  loginFailed,
  networkRetryFailed,
  networkRetryStarted,
  ordersCharityEnrichmentFailed,
  ordersCharityEnrichmentInvalid,
  ordersLoadFailed,
  ordersProductEnrichmentPartial,
  ordersResponseInvalid,
  profileListingsLoadFailed,
  profileListingsResponseInvalid,
  registrationFailed,
  unauthorisedRequest,
  unexpectedDeleteFailure,
  unexpectedGetFailure,
  unexpectedPostFailure,
  unexpectedPutFailure,
}

enum SafeLogLevel { info, warning, severe }

enum SafeHttpMethod { get, post, put, delete, patch, head, options, other }

enum SafeHttpOperation {
  createDonation,
  createOrder,
  createPaymentIntent,
  deleteAccount,
  findPickupPoints,
  loadCategories,
  loadCharities,
  loadLikedProducts,
  loadOrders,
  loadPostageSizes,
  loadProduct,
  loadProducts,
  loadProfile,
  loadProfileListings,
  loadShippingMethods,
  syncAuthentication,
  unclassifiedRequest,
  updateProductLike,
}

enum SafeHttpErrorCategory {
  badCertificate,
  cancelled,
  connection,
  httpResponse,
  timeout,
  unknown,
}

class SafeHttpLogRecord {
  const SafeHttpLogRecord({
    required this.method,
    required this.operation,
    required this.durationMs,
    this.statusCode,
    this.errorCategory,
  });

  final SafeHttpMethod method;
  final SafeHttpOperation operation;
  final int durationMs;
  final int? statusCode;
  final SafeHttpErrorCategory? errorCategory;

  Map<String, Object> get approvedMetadata => <String, Object>{
    'method': method.logName,
    'operation': operation.logName,
    'status': ?statusCode,
    'duration_ms': durationMs < 0 ? 0 : durationMs,
    'error_category': ?errorCategory?.logName,
  };

  String toLogLine() {
    final metadata = approvedMetadata;
    final fields = <String>[
      'HTTP',
      metadata['method']! as String,
      metadata['operation']! as String,
      'status=${metadata['status'] ?? 'unavailable'}',
      'duration_ms=${metadata['duration_ms']}',
      if (metadata['error_category'] case final String category) 'error_category=$category',
    ];
    return fields.join(' ');
  }
}

class SafeLog {
  const SafeLog._();

  static void event(
    AppLogEvent event, {
    SafeLogLevel level = SafeLogLevel.info,
  }) {
    _write('${level.name.toUpperCase()} event=${event.logName}');
  }

  static void count(
    AppLogEvent event,
    int count, {
    SafeLogLevel level = SafeLogLevel.info,
  }) {
    final safeCount = count < 0 ? 0 : count;
    _write('${level.name.toUpperCase()} event=${event.logName} count=$safeCount');
  }

  static void http(SafeHttpLogRecord record) {
    _write(record.toLogLine());
  }

  static void _write(String message) {
    if (!kDebugMode) {
      return;
    }

    try {
      debugPrint(message);
    } catch (_) {
      // Diagnostics must never change application behaviour.
    }
  }
}

extension on AppLogEvent {
  String get logName => _enumNameToSnakeCase(name);
}

extension on SafeHttpMethod {
  String get logName => name.toUpperCase();
}

extension on SafeHttpOperation {
  String get logName => _enumNameToSnakeCase(name);
}

extension on SafeHttpErrorCategory {
  String get logName => _enumNameToSnakeCase(name);
}

String _enumNameToSnakeCase(String value) {
  return value.replaceAllMapped(
    RegExp('([A-Z])'),
    (match) => '_${match.group(1)!.toLowerCase()}',
  );
}
