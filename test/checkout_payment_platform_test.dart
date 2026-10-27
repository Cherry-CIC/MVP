import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/models/inpost.dart';
import 'package:cherry_mvp/core/models/inpost_shipping_method.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/checkout/checkout_page.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/select_payment_type_bottom_sheet.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late _CheckoutRepository repository;
  late CheckoutViewModel viewModel;

  setUp(() {
    repository = _CheckoutRepository();
    viewModel = CheckoutViewModel(
      checkoutRepository: repository,
      donationRepository: _DonationRepository(),
      navigator: NavigationProvider(),
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    viewModel.dispose();
  });

  for (final platform in TargetPlatform.values) {
    final eligibleTypes = [
      PaymentType.card,
      if (platform == TargetPlatform.iOS) PaymentType.apple,
      if (platform == TargetPlatform.android) PaymentType.google,
    ];

    for (final brightness in Brightness.values) {
      testWidgets(
        '${platform.name} shows only eligible rows in ${brightness.name} theme',
        (tester) async {
          await _openSelector(tester, viewModel, brightness: brightness);

          for (final type in PaymentType.values) {
            expect(find.text(_labels[type]!), eligibleTypes.contains(type) ? findsOneWidget : findsNothing);
          }
          expect(find.byType(Divider), findsNWidgets(eligibleTypes.length + 1));
          expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
          expect(
            tester.widget<BottomSheet>(find.byType(BottomSheet).last).backgroundColor,
            buildTheme(brightness).colorScheme.surface,
          );
          expect(repository.paymentRequests, 0);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant.only(platform),
      );
    }

    for (final type in PaymentType.values.where((type) => !eligibleTypes.contains(type))) {
      test('${platform.name} rejects stored ${type.name} before payment or order creation', () async {
        debugDefaultTargetPlatformOverride = platform;
        _prepareCheckout(viewModel);
        viewModel.setPaymentType(type);

        expect(viewModel.hasPaymentMethod, isFalse);
        expect(viewModel.canCheckout, isFalse);
        expect(viewModel.eligibleSelectedPaymentType, isNull);
        expect(await viewModel.payWithPaymentSheet(), isFalse);
        expect(viewModel.createOrderStatus.type, StatusType.failure);
        expect(viewModel.createOrderStatus.message, AppStrings.checkoutPaymentMethodRequired);
        expect(viewModel.selectedPaymentType, type);
        expect(repository.paymentRequests, 0);
        expect(repository.orderRequests, 0);
      });
    }
  }

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    final wallet = platform == TargetPlatform.iOS ? PaymentType.apple : PaymentType.google;
    final unsupported = platform == TargetPlatform.iOS ? PaymentType.google : PaymentType.apple;

    for (final type in [PaymentType.card, wallet]) {
      test('${platform.name} allows ${type.name} to reach payment creation', () async {
        debugDefaultTargetPlatformOverride = platform;
        _prepareCheckout(viewModel);
        viewModel.setPaymentType(type);

        expect(viewModel.hasPaymentMethod, isTrue);
        expect(viewModel.canCheckout, isTrue);
        await viewModel.payWithPaymentSheet();
        // The fake stops here. No Stripe sheet or real payment is created.
        expect(repository.paymentRequests, 1);
        expect(repository.orderRequests, 0);
      });

      testWidgets(
        '${platform.name} replaces stored ${unsupported.name} with chosen ${type.name} before confirming',
        (
          tester,
        ) async {
          viewModel.setPaymentType(unsupported);
          PaymentType? confirmed;
          await _openSelector(tester, viewModel, onConfirmed: (value) => confirmed = value);

          expect(viewModel.selectedPaymentType, unsupported);
          expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
          expect(
            tester
                .widgetList<RadioGroup<PaymentType>>(find.byType(RadioGroup<PaymentType>))
                .every((group) => group.groupValue == null),
            isTrue,
          );
          await tester.tap(find.text(AppStrings.continueText));
          await tester.pumpAndSettle();
          expect(confirmed, isNull);
          expect(find.byType(SelectPaymentTypeBottomSheet), findsOneWidget);

          final tile = find.widgetWithText(ListTile, _labels[type]!);
          // Exercise both the adaptive radio and the row tap interaction.
          await tester.tap(
            type == PaymentType.card ? find.descendant(of: tile, matching: find.byType(Radio<PaymentType>)) : tile,
          );
          await tester.pumpAndSettle();
          expect(viewModel.selectedPaymentType, type);
          expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
          await tester.tap(find.text(AppStrings.continueText));
          await tester.pumpAndSettle();

          expect(confirmed, type);
          expect(find.byType(SelectPaymentTypeBottomSheet), findsNothing);
          expect(repository.paymentRequests, 0);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant.only(platform),
      );
    }

    testWidgets(
      '${platform.name} checkout prompts again for an unsupported stored method',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        _prepareCheckout(viewModel);
        viewModel.setPaymentType(unsupported);
        await tester.pumpWidget(_app(viewModel, const CheckoutPage()));
        await tester.pumpAndSettle();
        // DeliveryOptions initialises these from the profile after its first frame.
        viewModel.setMobilePhoneNumber('07700900000');
        viewModel.setRecipientName('Test buyer');
        await tester.pump();

        expect(find.text(_labels[unsupported]!), findsNothing);
        expect(find.text(AppStrings.checkoutChoosePayment), findsWidgets);
        expect(viewModel.selectedPaymentType, unsupported);
        await tester.tap(find.widgetWithText(FilledButton, AppStrings.checkoutPay));
        await tester.pumpAndSettle();

        expect(find.byType(SelectPaymentTypeBottomSheet), findsOneWidget);
        expect(repository.paymentRequests, 0);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byType(SelectPaymentTypeBottomSheet), findsNothing);
        expect(viewModel.selectedPaymentType, unsupported);
        expect(repository.paymentRequests, 0);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(platform),
    );
  }
}

const _labels = {
  PaymentType.card: AppStrings.paymentMethodsCard,
  PaymentType.google: AppStrings.paymentMethodsGooglePay,
  PaymentType.apple: AppStrings.paymentMethodsApplePay,
};

Widget _app(CheckoutViewModel viewModel, Widget home, {Brightness brightness = Brightness.light}) {
  return ChangeNotifierProvider<CheckoutViewModel>.value(
    value: viewModel,
    child: MaterialApp(theme: buildTheme(brightness), home: home),
  );
}

Future<void> _openSelector(
  WidgetTester tester,
  CheckoutViewModel viewModel, {
  Brightness brightness = Brightness.light,
  ValueChanged<PaymentType?>? onConfirmed,
}) async {
  await tester.pumpWidget(
    _app(
      viewModel,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showModalBottomSheet<PaymentType>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const SelectPaymentTypeBottomSheet(),
              );
              onConfirmed?.call(result);
            },
            child: const Text('Choose payment'),
          ),
        ),
      ),
      brightness: brightness,
    ),
  );
  await tester.tap(find.text('Choose payment'));
  await tester.pumpAndSettle();
}

void _prepareCheckout(CheckoutViewModel viewModel) {
  viewModel
    ..addItem(
      const Product(
        id: 'product-1',
        userId: 'seller-1',
        name: 'Jumper',
        description: 'Blue jumper',
        quality: 'Good',
        productImages: [],
        donation: 20,
        price: 20,
        securityFee: 2,
        likes: 0,
        number: 1,
        size: 'M',
        postageSizeId: 'small',
      ),
    )
    ..setShippingAddress(PlaceDetails(formattedAddress: '1 High Street, London, SW1A 1AA', addressComponents: []))
    ..setDeliveryChoice(DeliveryType.pickup)
    ..setSelectedInpost(
      const Inpost(
        id: 'locker-1',
        name: 'InPost',
        carrier: 'inpost_gb',
        address: '1 High Street',
        postcode: 'SW1A 1AA',
        city: 'London',
        country: 'GB',
        lat: '51.5',
        long: '-0.1',
      ),
    )
    ..setSelectedInpostShippingMethod(
      const InpostShippingMethod(
        id: 'shipping-1',
        name: 'InPost Locker',
        deliveryType: 'pickup',
        deliveryMethodType: 'locker',
        pricePence: 300,
        currency: 'GBP',
        checkoutIdentifier: 'inpost',
      ),
    )
    ..setMobilePhoneNumber('07700900000')
    ..setRecipientName('Test buyer');
}

class _CheckoutRepository implements ICheckoutRepository {
  int paymentRequests = 0;
  int orderRequests = 0;

  @override
  Future<Result<PaymentIntentResponse>> createPaymentIntent({
    required String productId,
    required String shippingMethodId,
    required String pickupPointId,
    required String country,
    required String postalCode,
    required Map<String, dynamic> shipping,
    required Map<String, dynamic> pickupPoint,
  }) async {
    paymentRequests++;
    return Result.failure('Test stops before Stripe');
  }

  @override
  Future<Result> createOrder(Map<String, dynamic> order) async {
    orderRequests++;
    return Result.success(null);
  }

  @override
  Future<Result<UserCredentials>> fetchUserProfile() async => Result.failure('No profile in this test');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DonationRepository implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
