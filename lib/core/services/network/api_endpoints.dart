class ApiEndpoints {
  static const String products = '/products';
  static const String productsWithDetails = '/products/with-details';

  // Versioned endpoints (if we need API versioning)
  static const String apiVersion = 'v1';
  static String versioned(String endpoint) => '/$apiVersion$endpoint';

  static const String categories = '/categories';
  static const String inpostLockers = '/shipping/inpost/lockers';
  static const String charities = '/charities';
  static const String paymentIntent = '/payment/create-payment-intent';
  static const String createOrder = '/order/create';
}
