class ApiEndpoints {
  static const String products = '/products';
  static const String productsWithDetails = '/products/with-details';

  // Versioned endpoints (if we need API versioning)
  static const String apiVersion = 'v1';
  static String versioned(String endpoint) => '/$apiVersion$endpoint';

  static const String categories = '/categories';
  static const String charities = '/charities';
}
