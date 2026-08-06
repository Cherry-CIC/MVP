import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the Swagger-documented My Orders route', () {
    expect(ApiEndpoints.myOrders, '/api/order/my-orders');
  });

  test('encodes product identifiers in product detail routes', () {
    expect(
      ApiEndpoints.productById('product/with spaces'),
      '/api/products/product%2Fwith%20spaces',
    );
  });
}
