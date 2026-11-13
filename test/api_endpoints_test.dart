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

  test('encodes product identifiers in enriched product detail routes', () {
    expect(
      ApiEndpoints.productWithDetailsById('product/with spaces'),
      '/api/products/product%2Fwith%20spaces/with-details',
    );
  });

  test('uses report and encoded block routes', () {
    expect(ApiEndpoints.reports, '/api/reports');
    expect(
      ApiEndpoints.blockUser('user/with spaces'),
      '/api/blocks/user%2Fwith%20spaces',
    );
    expect(
      ApiEndpoints.blockCharity('charity/with spaces'),
      '/api/blocks/charities/charity%2Fwith%20spaces',
    );
  });

  test('encodes charity identifiers in charity profile and products routes', () {
    expect(
      ApiEndpoints.charityById('charity/with spaces'),
      '/api/charities/charity%2Fwith%20spaces',
    );
    expect(
      ApiEndpoints.charityProducts('charity/with spaces'),
      '/api/charities/charity%2Fwith%20spaces/products',
    );
  });
}
