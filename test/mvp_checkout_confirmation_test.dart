import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/checkout/checkout_complete_page.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/widgets/checkout_action_button.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class _MockCheckoutRepository extends Mock implements ICheckoutRepository {}

class _MockDonationRepository extends Mock implements IDonationRepository {}

void main() {
  testWidgets('CheckoutCompletePage hides post-purchase shortcuts for the MVP', (
    tester,
  ) async {
    final checkoutViewModel = CheckoutViewModel(
      checkoutRepository: _MockCheckoutRepository(),
      donationRepository: _MockDonationRepository(),
      navigator: NavigationProvider(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<CheckoutViewModel>.value(
        value: checkoutViewModel,
        child: const MaterialApp(home: CheckoutCompletePage()),
      ),
    );

    expect(find.text(AppStrings.checkoutOrderPlaced), findsOneWidget);
    expect(find.text(AppStrings.checkoutContinueShopping), findsOneWidget);
    expect(find.text(AppStrings.checkoutTrackOrders), findsNothing);
    expect(find.text(AppStrings.checkoutImpactSummary), findsNothing);
    expect(find.text(AppStrings.checkoutReview), findsNothing);
    expect(find.byType(CheckoutActionButton), findsNothing);
  });
}
