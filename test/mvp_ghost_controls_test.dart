import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/charity_page/widgets/charity_card.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/profile/profile_page.dart';
import 'package:cherry_mvp/features/settings/settings_model.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_toggle_section.dart';
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

class _FakeCategoryRepository implements ICategoryRepository {
  @override
  Future<Result<List<Category>>> fetchCategories() async {
    return Result.success(const []);
  }
}

class _FakeCharityRepository implements ICharityRepository {
  @override
  Future<Result<List<Charity>>> fetchCharities() async {
    return Result.success(const []);
  }
}

class _FakeDonationRepository implements IDonationRepository {
  @override
  Future<Result<List<PostageSizeInfo>>> fetchPostageSizes() async {
    return Result.success(const []);
  }

  @override
  Future<Result<DonationResponse>> submitDonation(DonationRequest request) async {
    return Result.failure('Not used in this test');
  }
}

AuthViewModel _authViewModel() {
  return AuthViewModel(
    loginRepository: _MockLoginRepository(),
    navigator: _MockNavigationProvider(),
    firebaseAuth: _MockFirebaseAuth(),
    firestore: _MockFirebaseFirestore(),
  );
}

Charity _charity() {
  final now = DateTime.parse('2026-01-01T00:00:00.000Z');
  return Charity(
    id: 'ghost-control-charity',
    name: 'Ghost Control Charity',
    imageUrl: AppImages.cherryLogo,
    description: 'A test charity description.',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('settings data hides actionless rows for the MVP', () {
    expect(dummyPersonalSection, isEmpty);
    expect(dummyShopSection, isEmpty);
    expect(
      dummyAccountSection.map((item) => item.title),
      isNot(contains(AppStrings.languageText)),
    );
    expect(
      dummySupportSection.map((item) => item.title),
      isNot(contains(AppStrings.chatWithUsText)),
    );
    expect(
      dummySupportSection.map((item) => item.title),
      contains(AppStrings.faqText),
    );
    expect(
      dummyAccountSection.map((item) => item.title),
      contains(AppStrings.logOutText),
    );
  });

  testWidgets('SettingsToggleSection hides the inactive Hide Listings toggle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SettingsToggleSection(
                isSwitchedDark: false,
                toggleSwitchDark: (_) {},
                isSwitchedHide: false,
                toggleSwitchHide: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.darkModeText), findsOneWidget);
    expect(find.text(AppStrings.listListingsText), findsNothing);
  });

  testWidgets('CharityCard hides the inactive See More link', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharityCard(charity: _charity()),
        ),
      ),
    );

    expect(find.text('Ghost Control Charity'), findsOneWidget);
    expect(find.text(AppStrings.seeMore), findsNothing);
  });

  testWidgets('ProfilePage hides the inactive Share button', (tester) async {
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

    expect(find.text(AppStrings.profileUserInfoTitle), findsOneWidget);
    expect(find.text(AppStrings.share), findsNothing);
  });

  testWidgets('DonationForm hides the inactive feedback prompt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DonationViewModel>(
            create: (_) => DonationViewModel(
              donationRepository: _FakeDonationRepository(),
              navigator: NavigationProvider(),
            ),
          ),
          ChangeNotifierProvider<CharityViewModel>(
            create: (_) => CharityViewModel(
              charityRepository: _FakeCharityRepository(),
              navigator: NavigationProvider(),
            ),
          ),
          ChangeNotifierProvider<CategoryViewModel>(
            create: (_) => CategoryViewModel(
              categoryRepository: _FakeCategoryRepository(),
              navigator: NavigationProvider(),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: DonationForm()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.thoughtsOnUpload), findsNothing);
    expect(find.text(AppStrings.giveFeedback), findsNothing);
  });
}
