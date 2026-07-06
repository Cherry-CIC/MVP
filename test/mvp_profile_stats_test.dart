import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/profile/profile_page.dart';
import 'package:cherry_mvp/features/profile/widgets/user_information_section.dart';
import 'package:cherry_mvp/features/profile/widgets/user_order_details.dart';
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

AuthViewModel _authViewModel() {
  return AuthViewModel(
    loginRepository: _MockLoginRepository(),
    navigator: _MockNavigationProvider(),
    firebaseAuth: _MockFirebaseAuth(),
    firestore: _MockFirebaseFirestore(),
  );
}

UserInformation _userInformation() {
  return UserInformation(
    username: 'Profile Stats User',
    location: 'Cardiff',
    reviewsCount: 0,
    followersCount: 34,
    followingCount: 12,
    rating: 0,
    awards: 7,
    hasBuyerDiscounts: true,
  );
}

void main() {
  testWidgets('UserInformationSection hides placeholder profile stats', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: _authViewModel(),
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

    expect(
      find.textContaining(AppStrings.profileUserInfoSectionFollowing),
      findsNothing,
    );
    expect(
      find.textContaining(AppStrings.profileUserInfoSectionFollowers),
      findsNothing,
    );
    expect(find.text('Cardiff'), findsNothing);
    expect(
      find.textContaining(AppStrings.profileUserInfoSectionBuyerAwards),
      findsNothing,
    );
    expect(find.text(AppStrings.profileUserInfoSectionBuyerDiscount), findsNothing);
  });

  testWidgets('UserOrderDetails hides profile shortcut tiles for the MVP', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: UserOrderDetails())),
    );

    expect(find.text(AppStrings.profileUserOrders), findsNothing);
    expect(find.text(AppStrings.profileUserLiked), findsNothing);
    expect(find.text(AppStrings.profileUserListings), findsNothing);
    expect(find.text(AppStrings.profileUserBuyerDisc), findsNothing);
  });

  testWidgets('ProfilePage hides placeholder profile activity cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: _authViewModel()),
          Provider<NavigationProvider>.value(value: NavigationProvider()),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.profileUserOrders), findsNothing);
    expect(find.text(AppStrings.profileUserLiked), findsNothing);
    expect(find.text(AppStrings.profileUserListings), findsNothing);
    expect(find.text(AppStrings.profileUserActivityBought), findsNothing);
    expect(find.text(AppStrings.profileUserActivitySold), findsNothing);
    expect(find.text(AppStrings.profileUserActivityTotal), findsNothing);
  });
}
