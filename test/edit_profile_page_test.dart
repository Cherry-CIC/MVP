import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/profile/edit_profile_page.dart';
import 'package:cherry_mvp/features/profile/edit_profile_repository.dart';
import 'package:cherry_mvp/features/profile/edit_profile_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

class _MockLoginRepository extends Mock implements LoginRepository {}

class _MockNavigationProvider extends Mock implements NavigationProvider {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

/// Stands in for the real view model so the page can be pumped without a
/// Firestore-backed [AuthViewModel.loadCurrentUser].
class _TestAuthViewModel extends AuthViewModel {
  _TestAuthViewModel()
      : super(
          loginRepository: _MockLoginRepository(),
          navigator: _MockNavigationProvider(),
          firebaseAuth: _MockFirebaseAuth(),
          firestore: _MockFirebaseFirestore(),
          apiService: const UnexpectedApiService(),
        );

  void emitCredentials(UserCredentials credentials) {
    userCredentials = credentials;
    notifyListeners();
  }
}

class _StubEditProfileRepository implements IEditProfileRepository {
  @override
  Future<Result<void>> updateProfile({
    String? displayName,
    String? phoneNumber,
  }) async {
    return Result.success(null);
  }
}

Widget _wrap(AuthViewModel auth) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: auth),
      Provider<NavigationProvider>.value(value: _MockNavigationProvider()),
      ChangeNotifierProvider<EditProfileViewModel>(
        create: (_) => EditProfileViewModel(repository: _StubEditProfileRepository()),
      ),
    ],
    child: const MaterialApp(home: EditProfilePage()),
  );
}

Finder _fieldWithLabel(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byType(TextFormField),
  );
}

String _valueOf(WidgetTester tester, String label) {
  return tester.widget<EditableText>(
    find.descendant(of: _fieldWithLabel(label), matching: find.byType(EditableText)),
  ).controller.text;
}

final _credentials = UserCredentials(
  uid: 'uid-1',
  email: 'josh@example.com',
  username: 'josh',
  firstname: 'Joshua',
  phoneNumber: '07123456789',
);

void main() {
  group('EditProfilePage', () {
    testWidgets('shows a loading state until the profile has loaded',
        (tester) async {
      final auth = _TestAuthViewModel();

      await tester.pumpWidget(_wrap(auth));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);

      auth.emitCredentials(_credentials);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_valueOf(tester, AppStrings.editProfileFirstNameLabel), 'Joshua');
      expect(_valueOf(tester, AppStrings.editProfileUsernameLabel), 'josh');
      expect(_valueOf(tester, AppStrings.editProfilePhoneLabel), '07123456789');
      expect(_valueOf(tester, AppStrings.email), 'josh@example.com');
    });

    testWidgets('shows the email as read-only', (tester) async {
      final auth = _TestAuthViewModel();

      await tester.pumpWidget(_wrap(auth));
      auth.emitCredentials(_credentials);
      await tester.pump();

      final email = tester.widget<TextField>(
        find.descendant(of: _fieldWithLabel(AppStrings.email), matching: find.byType(TextField)),
      );

      expect(email.enabled, isFalse);
    });
  });
}
