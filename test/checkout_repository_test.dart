import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordedPost {
  _RecordedPost(this.endpoint, this.data);

  final String endpoint;
  final dynamic data;
}

class _CheckoutApiService implements ApiService {
  final List<_RecordedPost> posts = [];
  final List<dynamic> responses = [
    {
      'success': true,
      'message': 'Created',
      'data': {
        'orderId': 'order-123',
        'paymentIntentId': 'pi_123',
        'clientSecret': 'pi_123_secret_test',
        'ephemeralKey': 'ek_test',
        'customer': 'cus_test',
        'publishableKey': 'pk_test',
        'productAmount': 2500,
        'shippingFee': 399,
        'securityFee': 250,
        'totalAmount': 3149,
        'currency': 'GBP',
      },
    },
    {'success': true, 'message': 'Order finalized', 'data': {}},
  ];

  @override
  Future<Result<T>> post<T>(String endpoint, {dynamic data}) async {
    posts.add(_RecordedPost(endpoint, data));
    return Result.success(responses.removeAt(0) as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('checkout creates a pending order then confirms it with the same IDs', () async {
    final apiService = _CheckoutApiService();
    final repository = CheckoutRepository(apiService);
    final shipping = {
      'address': {
        'line1': '18 Calderwood Street',
        'city': 'London',
        'postal_code': 'SE18 6QW',
        'country': 'GB',
      },
      'name': 'Buyer Name',
      'telephone': '+447700900000',
    };
    final pickupPoint = {
      'id': '13127548',
      'name': 'InPost Locker',
      'addressLine1': '123 High Street',
      'city': 'London',
      'postalCode': 'SE7 8UG',
      'country': 'GB',
      'carrier': 'inpost_gb',
    };

    final paymentResult = await repository.createPaymentIntent(
      productId: 'product-1',
      shippingMethodId: '3747',
      pickupPointId: '13127548',
      country: 'GB',
      postalCode: 'SE18 4QH',
      shipping: shipping,
      pickupPoint: pickupPoint,
    );

    expect(paymentResult.isSuccess, isTrue);
    final payment = paymentResult.value!;
    expect(payment.orderId, 'order-123');
    expect(payment.paymentIntentId, 'pi_123');

    final confirmationResult = await repository.createOrder({
      'orderId': payment.orderId,
      'paymentIntentId': payment.paymentIntentId,
    });

    expect(confirmationResult.isSuccess, isTrue);
    expect(apiService.posts, hasLength(2));
    expect(apiService.posts[0].endpoint, ApiEndpoints.paymentIntent);
    expect(
      apiService.posts[0].data,
      {
        'productId': 'product-1',
        'shippingMethodId': '3747',
        'pickupPointId': '13127548',
        'country': 'GB',
        'postalCode': 'SE18 4QH',
        'shipping': shipping,
        'pickupPoint': pickupPoint,
      },
    );
    expect(apiService.posts[1].endpoint, ApiEndpoints.createOrder);
    expect(
      apiService.posts[1].data,
      {'orderId': 'order-123', 'paymentIntentId': 'pi_123'},
    );
  });
}
