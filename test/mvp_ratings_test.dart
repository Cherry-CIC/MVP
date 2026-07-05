import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/products/widgets/seller_information.dart';
import 'package:cherry_mvp/features/profile/widgets/user_information_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class _MockLoginRepository extends Mock implements LoginRepository {}

class _MockNavigationProvider extends Mock implements NavigationProvider {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

UserInformation _userInformation() {
  return UserInformation(
    username: 'Rating Test User',
    location: 'United Kingdom',
    reviewsCount: 12,
    followersCount: 0,
    followingCount: 0,
    rating: 4.5,
    awards: 0,
    hasBuyerDiscounts: false,
  );
}

void _expectNoRatings() {
  expect(find.byIcon(Icons.star), findsNothing);
  expect(find.byIcon(Icons.star_half), findsNothing);
  expect(find.byIcon(Icons.star_border), findsNothing);
  expect(find.textContaining(AppStrings.profileUserInfoSectionBuyerReviews), findsNothing);
  expect(find.text('(12)'), findsNothing);
}

void main() {
  testWidgets('SellerInformation hides ratings for the MVP', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SellerInformation(
            user: _userInformation(),
            charity: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('Rating Test User'), findsOneWidget);
    _expectNoRatings();
  });

  testWidgets('UserInformationSection hides ratings for the MVP', (tester) async {
    final authViewModel = AuthViewModel(
      loginRepository: _MockLoginRepository(),
      navigator: _MockNavigationProvider(),
      firebaseAuth: _MockFirebaseAuth(),
      firestore: _MockFirebaseFirestore(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: authViewModel,
        child: MaterialApp(
          home: Scaffold(
            body: UserInformationSection(
              userInformationSection: _userInformation(),
              onSettingsPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsWidgets);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    _expectNoRatings();
  });
}
