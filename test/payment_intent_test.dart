import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';

void main() {
  test('PaymentIntentResponse keeps the backend payment intent id', () {
    final response = PaymentIntentResponse.fromJson({
      'success': true,
      'message': 'Created',
      'data': {
        'paymentIntentId': 'pi_123',
        'clientSecret': 'pi_123_secret_abc',
        'ephemeralKey': 'ek_test_123',
        'customer': 'cus_123',
        'publishableKey': 'pk_test_123',
      },
    });

    expect(response.paymentIntentId, 'pi_123');
    expect(response.paymentIntent, 'pi_123_secret_abc');
  });

  test('PaymentIntentResponse falls back to the id in the client secret', () {
    final response = PaymentIntentResponse.fromJson({
      'success': true,
      'message': 'Created',
      'data': {
        'clientSecret': 'pi_456_secret_def',
        'ephemeralKey': '',
        'customer': '',
        'publishableKey': 'pk_test_456',
      },
    });

    expect(response.paymentIntentId, 'pi_456');
  });
}
