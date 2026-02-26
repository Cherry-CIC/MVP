class ApiEndpoints {
  static const String _apiPrefix = '/api';

  static const String products = '$_apiPrefix/products';
  static const String productsWithDetails = '$_apiPrefix/products/with-details';

  // Auth sync
  static const String authSync = '$_apiPrefix/auth/sync';

  // Versioned endpoints (if we need API versioning)
  static const String apiVersion = 'v1';
  static String versioned(String endpoint) => '/$apiVersion$endpoint';

  static const String categories = '$_apiPrefix/categories';
  static const String inpostLockers = '$_apiPrefix/shipping/inpost/lockers';
  static const String charities = '$_apiPrefix/charities';
  static const String paymentIntent = '$_apiPrefix/payment/create-payment-intent';
  static const String createOrder = '$_apiPrefix/order/create';
}
