import 'dart:async';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/checkout_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CheckoutFixture fixture;
  late FakePaymentSheet sheet;

  setUp(() {
    fixture = CheckoutFixture()..selectValidDelivery();
    sheet = FakePaymentSheet()..install();
  });
  tearDown(() {
    fixture.viewModel.dispose();
    sheet.uninstall();
  });

  for (final field in ['id', 'name', 'address', 'city', 'postcode', 'country']) {
    test('missing pickup $field prevents payment at the view-model boundary', () async {
      final vm = fixture.viewModel;
      final point = CheckoutFixture.pickupPoint(missing: field);
      vm.setSelectedInpost(point);
      final states = <StatusType>[];
      vm.addListener(() => states.add(vm.createOrderStatus.type));

      expect(await vm.payWithPaymentSheet(), isFalse);
      expect(vm.deliveryError, AppStrings.checkoutPickupDetailsIncomplete);
      expect(fixture.repository.intentRequests, isEmpty);
      expect(sheet.calls, isEmpty);
      expect(states, isNot(contains(StatusType.loading)));
      expect(vm.selectedInpost, same(point));
      expect(vm.mobilePhoneNumber, '07700 900123');
      expect(vm.isCheckoutInProgress, isFalse);
    });
  }

  final invalidSelections = <String, void Function(CheckoutViewModel)>{
    'undefined delivery': (vm) => vm.setDeliveryChoice(DeliveryType.undefined),
    'no pickup': (vm) => vm.setSelectedInpost(null),
    'no shipping method': (vm) => vm.setSelectedInpostShippingMethod(null),
    'invalid country': (vm) => vm.setSelectedInpost(CheckoutFixture.pickupPoint(country: 'invalid')),
    'empty phone': (vm) => vm.setMobilePhoneNumber(''),
    'blank phone': (vm) => vm.setMobilePhoneNumber('   '),
    'unconfirmed home address': (vm) => vm.setDeliveryChoice(DeliveryType.home),
  };
  for (final entry in invalidSelections.entries) {
    test('${entry.key} makes zero payment requests', () async {
      entry.value(fixture.viewModel);
      expect(await fixture.viewModel.payWithPaymentSheet(), isFalse);
      expect(fixture.repository.intentRequests, isEmpty);
      expect(sheet.calls, isEmpty);
      expect(fixture.viewModel.deliveryError ?? fixture.viewModel.mobilePhoneError, isNotNull);
    });
  }

  test('a corrected retry creates one intent and submits the corrected details', () async {
    final vm = fixture.viewModel;
    vm.setSelectedInpost(CheckoutFixture.pickupPoint(missing: 'city'));
    vm.setMobilePhoneNumber('');
    expect(await vm.payWithPaymentSheet(), isFalse);
    expect(fixture.repository.intentRequests, isEmpty);

    vm.setSelectedInpost(CheckoutFixture.pickupPoint());
    vm.setMobilePhoneNumber('+44 7700 900456');
    expect(await vm.payWithPaymentSheet(), isTrue);
    await vm.createOrder();

    expect(fixture.repository.intentRequests, hasLength(1));
    expect(sheet.calls.where((call) => call == 'presentPaymentSheet'), hasLength(1));
    expect(fixture.repository.orders, hasLength(1));
    expect(fixture.repository.orders.single, {
      'productId': 'product-1',
      'paymentIntentId': 'pi_test',
      'shipping': {
        'address': {'line1': '12 High Street, Shop', 'city': 'London', 'postal_code': 'SW1A 1AA', 'country': 'GB'},
        'name': 'Customer',
        'telephone': '+44 7700 900456',
      },
      'pickupPoint': {
        'id': 'locker-1',
        'name': 'High Street',
        'addressLine1': '12 High Street, Shop',
        'city': 'London',
        'postalCode': 'SW1A 1AA',
        'country': 'GB',
        'carrier': 'inpost',
      },
    });
    expect(vm.createOrderStatus.type, StatusType.success);
    expect(vm.isCheckoutInProgress, isFalse);
  });

  test('intent, sheet and order stages retain validated state and reject repeated submissions', () async {
    final vm = fixture.viewModel;
    final point = vm.selectedInpost;
    fixture.repository.pendingIntent = Completer<Result<PaymentIntentResponse>>();
    fixture.repository.pendingOrder = Completer<Result>();
    sheet.pendingPresentation = Completer<Map<String, dynamic>>();

    void tryChangingDetails() {
      vm.setSelectedInpost(null);
      vm.setSelectedInpostShippingMethod(null);
      vm.setDeliveryChoice(DeliveryType.undefined);
      vm.setMobilePhoneNumber('');
      vm.setPaymentType(PaymentType.apple);
      vm.clearBasket();
      vm.removeItem(CheckoutFixture.product);
      vm.resetCheckout();
      expect(vm.addItem(CheckoutFixture.product), isFalse);
      expect(vm.selectedInpost, same(point));
      expect(vm.selectedInpostShippingMethod, CheckoutFixture.shippingMethod);
      expect(vm.deliveryChoice, DeliveryType.pickup);
      expect(vm.mobilePhoneNumber, '07700 900123');
      expect(vm.selectedPaymentType, PaymentType.card);
      expect(vm.basketItems, hasLength(1));
      expect(vm.isCheckoutInProgress, isTrue);
    }

    final paying = vm.payWithPaymentSheet();
    tryChangingDetails();
    expect(await vm.payWithPaymentSheet(), isFalse);
    await vm.createOrder(); // Premature programmatic call must not unlock payment.
    expect(fixture.repository.orders, isEmpty);
    expect(vm.isCheckoutInProgress, isTrue);
    fixture.repository.pendingIntent!.complete(RecordingCheckoutRepository.successfulPayment());
    await sheet.presented.future;
    tryChangingDetails();
    sheet.pendingPresentation!.complete({});
    expect(await paying, isTrue);
    tryChangingDetails();

    final ordering = vm.createOrder();
    tryChangingDetails();
    await vm.createOrder();
    expect(await vm.payWithPaymentSheet(), isFalse);
    expect(fixture.repository.orders, hasLength(1));
    fixture.repository.pendingOrder!.complete(Result.success({}));
    await ordering;
    expect(fixture.repository.intentRequests, hasLength(1));
    expect(fixture.repository.orders.single['shipping']['telephone'], '07700 900123');
    expect(vm.isCheckoutInProgress, isFalse);
  });

  test('late untouched profile cannot change a payment attempt', () async {
    fixture.viewModel.resetCheckout();
    fixture.selectValidDelivery(setPhone: false);
    fixture.repository.profile = Result.success(UserCredentials(uid: 'buyer', email: '', phoneNumber: '07700 900123'));
    await fixture.viewModel.prefillMobilePhoneNumber();
    fixture.repository.pendingProfile = Completer<Result<UserCredentials>>();
    final prefilling = fixture.viewModel.prefillMobilePhoneNumber();
    fixture.repository.pendingIntent = Completer<Result<PaymentIntentResponse>>();
    final paying = fixture.viewModel.payWithPaymentSheet();
    fixture.repository.pendingProfile!.complete(
      Result.success(UserCredentials(uid: 'buyer', email: '', phoneNumber: '07700 900999')),
    );
    await prefilling;
    expect(fixture.viewModel.mobilePhoneNumber, '07700 900123');
    fixture.repository.pendingIntent!.complete(RecordingCheckoutRepository.successfulPayment());
    expect(await paying, isTrue);
    await fixture.viewModel.createOrder();
    expect(fixture.repository.orders.single['shipping']['telephone'], '07700 900123');
  });

  test('old profile response is ignored after checkout reset', () async {
    fixture.repository.pendingProfile = Completer<Result<UserCredentials>>();
    final prefilling = fixture.viewModel.prefillMobilePhoneNumber();
    fixture.viewModel.resetCheckout();
    fixture.repository.pendingProfile!.complete(
      Result.success(UserCredentials(uid: 'buyer', email: '', phoneNumber: 'old')),
    );
    await prefilling;
    expect(fixture.viewModel.mobilePhoneNumber, isEmpty);
    fixture.repository.pendingProfile = null;
    fixture.repository.profile = Result.success(UserCredentials(uid: 'buyer', email: '', phoneNumber: 'new'));
    await fixture.viewModel.prefillMobilePhoneNumber();
    expect(fixture.viewModel.mobilePhoneNumber, 'new');
  });

  test('intent failure unlocks fields and permits a deliberate retry', () async {
    fixture.repository.intentFailure = Result.failure('Unavailable');
    expect(await fixture.viewModel.payWithPaymentSheet(), isFalse);
    expect(fixture.viewModel.isCheckoutInProgress, isFalse);
    expect(sheet.calls, isEmpty);
    fixture.viewModel.setMobilePhoneNumber('07700 900456');
    fixture.repository.intentFailure = null;
    expect(await fixture.viewModel.payWithPaymentSheet(), isTrue);
    await fixture.viewModel.createOrder();
    expect(fixture.repository.intentRequests, hasLength(2));
    expect(fixture.repository.orders.single['shipping']['telephone'], '07700 900456');
  });

  test('sheet cancellation unlocks checkout without creating an order', () async {
    sheet.cancel = true;
    expect(await fixture.viewModel.payWithPaymentSheet(), isFalse);
    expect(fixture.viewModel.isCheckoutInProgress, isFalse);
    expect(fixture.viewModel.createOrderStatus.type, StatusType.failure);
    expect(fixture.viewModel.lastPaymentIntentId, isNull);
    await fixture.viewModel.createOrder();
    expect(fixture.repository.orders, isEmpty);
    fixture.viewModel.setMobilePhoneNumber('07700 900456');
    expect(fixture.viewModel.mobilePhoneNumber, '07700 900456');
  });

  test('unexpected order error is sanitised and releases the submission lock', () async {
    fixture.repository.pendingOrder = Completer<Result>();
    expect(await fixture.viewModel.payWithPaymentSheet(), isTrue);
    final ordering = fixture.viewModel.createOrder();
    fixture.repository.pendingOrder!.completeError(StateError('Private error detail'));
    await ordering;
    expect(fixture.viewModel.createOrderStatus.message, 'Order could not be created. Please try again.');
    expect(fixture.viewModel.isCheckoutInProgress, isFalse);
    expect(fixture.viewModel.mobilePhoneNumber, '07700 900123');
    fixture.repository.pendingOrder = null;
    await fixture.viewModel.createOrder();
    expect(fixture.repository.orders, hasLength(2));
    expect(fixture.viewModel.createOrderStatus.type, StatusType.success);
  });

  test('order failure unlocks checkout and retains entered details', () async {
    fixture.repository.pendingOrder = Completer<Result>();
    expect(await fixture.viewModel.payWithPaymentSheet(), isTrue);
    final ordering = fixture.viewModel.createOrder();
    fixture.repository.pendingOrder!.complete(Result.failure('Unavailable'));
    await ordering;
    expect(fixture.viewModel.createOrderStatus.type, StatusType.failure);
    expect(fixture.viewModel.isCheckoutInProgress, isFalse);
    expect(fixture.viewModel.mobilePhoneNumber, '07700 900123');
    expect(fixture.viewModel.selectedInpost, isNotNull);
  });
}
