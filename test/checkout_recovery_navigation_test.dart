import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/inpost.dart';
import 'package:cherry_mvp/core/models/inpost_shipping_method.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_complete_page.dart';
import 'package:cherry_mvp/features/checkout/checkout_page.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _CheckoutRepository implements ICheckoutRepository {
  int intentCount = 0;
  final orders = <Map<String, dynamic>>[];

  @override
  Future<Result<PaymentIntentResponse>> createPaymentIntent({
    required String productId,
    required String shippingMethodId,
    required String pickupPointId,
    required String country,
    required String postalCode,
    int? expectedEditVersion,
  }) async {
    intentCount++;
    return Result.success(
      PaymentIntentResponse(
        success: true,
        message: 'Created',
        data: PaymentIntentData(
          paymentIntentId: 'pi_paid',
          paymentIntent: 'pi_paid_secret_test',
          ephemeralKey: '',
          customer: '',
          publishableKey: 'pk_test_example',
        ),
      ),
    );
  }

  @override
  Future<Result> createOrder(Map<String, dynamic> order) async {
    orders.add(Map<String, dynamic>.from(order));
    return orders.length == 1 ? Result.failure('Connection lost. Please try again.') : Result.success(null);
  }

  @override
  Future<Result<UserCredentials>> fetchUserProfile() async => Result.failure('No saved profile');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected checkout operation');
}

class _DonationRepository implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected donation operation');
}

final _product = Product.fromJson({
  'id': 'listing-1',
  'userId': 'seller-1',
  'name': 'Blue shirt',
  'description': 'A cotton shirt.',
  'quality': 'GOOD',
  'product_images': <String>[],
  'price': 10,
  'securityFee': 1,
  'number': 1,
  'size': 'M',
  'postageSize': 'small',
  'categoryId': 'shirts',
  'charityId': 'charity-1',
  'status': 'active',
  'editVersion': 7,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const stripeChannel = MethodChannel('flutter.stripe/payments', JSONMethodCodec());
  const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');
  late _CheckoutRepository repository;
  late CheckoutViewModel viewModel;
  late NavigationProvider navigator;
  late List<String> stripeCalls;

  setUp(() {
    repository = _CheckoutRepository();
    navigator = NavigationProvider();
    viewModel = CheckoutViewModel(
      donationRepository: _DonationRepository(),
      checkoutRepository: repository,
      navigator: navigator,
      currentUserIdProvider: () => 'buyer-1',
      loadProduct: (_) async => Result.success(_product),
    );
    stripeCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(stripeChannel, (
      call,
    ) async {
      stripeCalls.add(call.method);
      return <String, dynamic>{};
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      toastChannel,
      (_) async => true,
    );
  });

  tearDown(() {
    viewModel.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(stripeChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(toastChannel, null);
  });

  Future<void> openCheckout(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    viewModel.addItem(_product);
    viewModel.setPaymentType(PaymentType.card);
    viewModel.setSelectedInpost(
      Inpost(
        id: '123',
        name: 'High Street',
        carrier: 'inpost',
        address: '1 High Street',
        postcode: 'SW1A 1AA',
        city: 'London',
        country: 'GB',
        lat: '51.5',
        long: '-0.1',
      ),
    );
    viewModel.setSelectedInpostShippingMethod(
      InpostShippingMethod(
        id: '456',
        name: 'Locker delivery',
        deliveryType: 'pickup',
        deliveryMethodType: 'inpost',
        pricePence: 250,
        currency: 'GBP',
        checkoutIdentifier: '456',
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<CheckoutViewModel>.value(
        value: viewModel,
        child: MaterialApp(
          navigatorKey: navigator.navigatorKey,
          home: const Scaffold(body: Text('Listing page')),
          routes: {
            AppRoutes.checkout: (_) => const CheckoutPage(),
            AppRoutes.checkoutComplete: (_) => const CheckoutCompletePage(),
            AppRoutes.home: (_) => const Scaffold(body: Text('Home page')),
          },
        ),
      ),
    );
    navigator.navigateTo(AppRoutes.checkout);
    await tester.pumpAndSettle();
    viewModel.setMobilePhoneNumber('07700900001');
    await tester.pump();
  }

  testWidgets('an unpaid checkout can close and clear its basket', (tester) async {
    await openCheckout(tester);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Listing page'), findsOneWidget);
    expect(viewModel.basketItems, isEmpty);
    expect(repository.intentCount, 0);
  });

  testWidgets('a paid order failure survives Close and Back, then retries the same payment successfully', (
    tester,
  ) async {
    await openCheckout(tester);
    await tester.tap(find.text(AppStrings.checkoutPay));
    await tester.pumpAndSettle();
    expect(repository.orders, hasLength(1));
    expect(viewModel.lastPaymentIntentId, 'pi_paid');

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Listing page'), findsOneWidget);
    expect(viewModel.basketItems.single.id, 'listing-1');
    expect(viewModel.lastPaymentIntentId, 'pi_paid');

    navigator.navigateTo(AppRoutes.checkout);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Listing page'), findsOneWidget);
    expect(viewModel.lastPaymentIntentId, 'pi_paid');

    navigator.navigateTo(AppRoutes.checkout);
    await tester.pumpAndSettle();
    viewModel.setMobilePhoneNumber('07700900001');
    await tester.pump();
    await tester.tap(find.text(AppStrings.checkoutPay));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutCompletePage), findsOneWidget);
    expect(repository.orders, hasLength(2));
    expect(repository.orders.map((order) => order['paymentIntentId']), ['pi_paid', 'pi_paid']);
    expect(repository.intentCount, 1);
    expect(stripeCalls.where((method) => method == 'presentPaymentSheet'), hasLength(1));

    await tester.ensureVisible(find.text(AppStrings.checkoutContinueShopping));
    await tester.tap(find.text(AppStrings.checkoutContinueShopping));
    await tester.pumpAndSettle();
    expect(find.text('Home page'), findsOneWidget);
    expect(viewModel.lastPaymentIntentId, isNull);
    expect(viewModel.basketItems, isEmpty);
  });
}
