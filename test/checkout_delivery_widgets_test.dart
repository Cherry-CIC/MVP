import 'dart:async';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_page.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/widgets/delivery_options.dart';
import 'package:cherry_mvp/features/checkout/widgets/select_payment_type_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/checkout_fakes.dart';

void main() {
  late CheckoutFixture fixture;
  late FakePaymentSheet sheet;
  const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');

  setUp(() {
    fixture = CheckoutFixture()..selectValidDelivery(setPhone: false);
    sheet = FakePaymentSheet()..install();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      toastChannel,
      (_) async => true,
    );
  });
  tearDown(() {
    fixture.viewModel.dispose();
    sheet.uninstall();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(toastChannel, null);
  });

  Future<void> showCheckout(WidgetTester tester, {bool page = false, bool large = true}) async {
    if (large) {
      await tester.binding.setSurfaceSize(const Size(800, 1500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }
    await tester.pumpWidget(
      ChangeNotifierProvider<CheckoutViewModel>.value(
        value: fixture.viewModel,
        child: MaterialApp(
          home: page ? const CheckoutPage() : const Scaffold(body: CustomScrollView(slivers: [DeliveryOptions()])),
        ),
      ),
    );
    await tester.pump();
  }

  String visiblePhone(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('typing is immediate and late profile/rebuilds preserve the edit', (tester) async {
    fixture.repository.pendingProfile = Completer<Result<UserCredentials>>();
    await showCheckout(tester);
    await tester.enterText(find.byType(TextField), '07700 900456');
    expect(fixture.viewModel.mobilePhoneNumber, '07700 900456');
    fixture.repository.pendingProfile!.complete(
      Result.success(UserCredentials(uid: 'buyer', email: '', phoneNumber: '07700 900999')),
    );
    await tester.pump();
    fixture.viewModel.setAddressConfirmed(false); // Unrelated notifier rebuild.
    await tester.pump();
    expect(visiblePhone(tester), '07700 900456');
    expect(fixture.viewModel.mobilePhoneNumber, '07700 900456');

    await tester.pumpWidget(const SizedBox());
    await showCheckout(tester, large: false); // Recreate controller in the same checkout session.
    expect(visiblePhone(tester), '07700 900456');
  });

  testWidgets('untouched profile prefills but a deliberately cleared phone stays empty', (tester) async {
    fixture.repository.profile = Result.success(UserCredentials(uid: 'buyer', email: '', phoneNumber: '07700 900999'));
    await showCheckout(tester);
    expect(visiblePhone(tester), '07700 900999');
    expect(fixture.viewModel.mobilePhoneNumber, '07700 900999');
    await tester.enterText(find.byType(TextField), '');
    await fixture.viewModel.prefillMobilePhoneNumber();
    await tester.pump();
    expect(visiblePhone(tester), isEmpty);
    expect(fixture.viewModel.mobilePhoneNumber, isEmpty);
    expect(await fixture.viewModel.payWithPaymentSheet(), isFalse);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.errorText,
      AppStrings.checkoutMobilePhoneRequired,
    );
    expect(fixture.repository.intentRequests, isEmpty);
  });

  testWidgets('Pay submits the visible edit without keyboard submission or outside tap', (tester) async {
    fixture.repository.pendingProfile = Completer<Result<UserCredentials>>();
    fixture.repository.pendingIntent = Completer<Result<PaymentIntentResponse>>();
    fixture.repository.pendingOrder = Completer<Result>();
    sheet.pendingPresentation = Completer<Map<String, dynamic>>();
    await showCheckout(tester, page: true);
    await tester.enterText(find.byType(TextField), '+44 7700 900456');
    final pay = find.widgetWithText(FilledButton, AppStrings.checkoutPay);
    await tester.tap(pay);
    await tester.tap(pay); // Before the disabled-state rebuild.
    await tester.pump();
    expect(fixture.repository.intentRequests, hasLength(1));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close)).onPressed, isNull);
    expect(tester.widget<PopScope>(find.byWidgetPredicate((widget) => widget is PopScope)).canPop, isFalse);

    fixture.repository.pendingProfile!.complete(
      Result.success(UserCredentials(uid: 'buyer', email: '', phoneNumber: '07700 900999')),
    );
    fixture.repository.pendingIntent!.complete(RecordingCheckoutRepository.successfulPayment());
    await tester.pump();
    expect(sheet.calls, contains('presentPaymentSheet'));
    expect(visiblePhone(tester), '+44 7700 900456');
    sheet.pendingPresentation!.complete({});
    await tester.pump();
    expect(fixture.repository.orders, hasLength(1));
    expect(fixture.repository.orders.single['shipping']['telephone'], visiblePhone(tester));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    fixture.repository.pendingOrder!.complete(Result.success({}));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Existing success navigation delay.
    expect(fixture.repository.intentRequests, hasLength(1));
    expect(fixture.repository.orders, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid pickup error is inline and the corrected Pay retries once', (tester) async {
    fixture.viewModel.setSelectedInpost(CheckoutFixture.pickupPoint(missing: 'city'));
    fixture.viewModel.setMobilePhoneNumber('07700 900123');
    await showCheckout(tester, page: true);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.checkoutPay));
    await tester.pump();
    expect(find.text(AppStrings.checkoutPickupDetailsIncomplete), findsOneWidget);
    expect(fixture.repository.intentRequests, isEmpty);
    expect(sheet.calls, isEmpty);
    expect(visiblePhone(tester), '07700 900123');

    fixture.viewModel.setSelectedInpost(CheckoutFixture.pickupPoint());
    fixture.repository.intentFailure = Result.failure('Test request stopped');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.checkoutPay));
    await tester.pump();
    expect(fixture.repository.intentRequests, hasLength(1));
    expect(find.text(AppStrings.checkoutPickupDetailsIncomplete), findsNothing);
    await tester.pump(const Duration(seconds: 1)); // Existing toast cooldown.
  });

  testWidgets('Pay brings a required phone error into view on a small screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await showCheckout(tester, page: true, large: false);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.checkoutPay));
    await tester.pumpAndSettle();
    expect(fixture.repository.intentRequests, isEmpty);
    expect(find.text(AppStrings.checkoutMobilePhoneRequired).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated Pay opens one method chooser and dismissing it unlocks checkout', (tester) async {
    fixture.viewModel.setMobilePhoneNumber('07700 900123');
    fixture.viewModel.clearPaymentMethod();
    await showCheckout(tester, page: true);
    final payCallback = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, AppStrings.checkoutPay))
        .onPressed!;
    payCallback();
    payCallback();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // Sheet entrance; the Pay spinner keeps animating.
    expect(find.byType(SelectPaymentTypeBottomSheet), findsOneWidget);
    expect(fixture.repository.intentRequests, isEmpty);
    Navigator.of(tester.element(find.byType(SelectPaymentTypeBottomSheet))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(SelectPaymentTypeBottomSheet), findsNothing);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, AppStrings.checkoutPay)).onPressed, isNotNull);
    expect(fixture.viewModel.mobilePhoneNumber, '07700 900123');
  });
}
