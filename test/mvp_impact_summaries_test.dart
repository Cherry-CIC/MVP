import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/checkout/checkout_complete_page.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/profile/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class _MockCheckoutRepository extends Mock implements ICheckoutRepository {}

class _MockDonationRepository extends Mock implements IDonationRepository {}

class _MockLoginRepository extends Mock implements LoginRepository {}

class _MockNavigationProvider extends Mock implements NavigationProvider {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  testWidgets('ProfilePage hides static impact summary for the MVP', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authViewModel = AuthViewModel(
      loginRepository: _MockLoginRepository(),
      navigator: _MockNavigationProvider(),
      firebaseAuth: _MockFirebaseAuth(),
      firestore: _MockFirebaseFirestore(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
          Provider<NavigationProvider>.value(value: NavigationProvider()),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.profileYourDonationImpact), findsNothing);
    expect(find.text(AppStrings.profileGenerosityChangesLives), findsNothing);
    expect(find.text('£365.00'), findsNothing);
  });

  testWidgets('CheckoutCompletePage hides impact summary action for the MVP', (
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
    expect(find.text(AppStrings.checkoutImpactSummary), findsNothing);
    expect(find.text(AppStrings.checkoutContinueShopping), findsOneWidget);
  });
}
