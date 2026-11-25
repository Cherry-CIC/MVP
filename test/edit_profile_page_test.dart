import 'dart:convert';

import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:cherry_mvp/core/models/profile_photo.dart';
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

class _TestPicker extends ImagePickerPlatform {
  XFile? selection;
  int calls = 0;

  @override
  Future<XFile?> getImageFromSource({required ImageSource source, ImagePickerOptions options = const ImagePickerOptions()}) async {
    calls++;
    expect(source, ImageSource.gallery);
    expect(options.requestFullMetadata, isFalse);
    return selection;
  }
}

class _TestUser extends Mock implements User {
  @override
  String get uid => 'uid-1';
}

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

  @override
  User get currentUser => _TestUser();

  @override
  Future<void> loadCurrentUser() async {}

  void emitCredentials(UserCredentials credentials) {
    userCredentials = credentials;
    notifyListeners();
  }
}

class _StubEditProfileRepository implements IEditProfileRepository {
  ProfilePhoto? savedPhoto;
  @override
  Future<Result<void>> updateProfile({
    required String uid,
    ProfilePhoto? photo,
    String? displayName,
    String? phoneNumber,
  }) async {
    savedPhoto = photo;
    return Result.success(null);
  }
}

Widget _wrap(AuthViewModel auth, [_StubEditProfileRepository? repository]) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: auth),
      Provider<NavigationProvider>.value(value: _MockNavigationProvider()),
      ChangeNotifierProvider<EditProfileViewModel>(
        create: (_) => EditProfileViewModel(repository: repository ?? _StubEditProfileRepository()),
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
      expect(find.text(AppStrings.addProfilePhoto), findsOneWidget);
    });

    testWidgets('cancelling Add photo keeps the original avatar', (tester) async {
      final original = ImagePickerPlatform.instance;
      addTearDown(() => ImagePickerPlatform.instance = original);
      final picker = _TestPicker();
      ImagePickerPlatform.instance = picker;
      final auth = _TestAuthViewModel()..emitCredentials(_credentials);
      await tester.pumpWidget(_wrap(auth));
      await tester.tap(find.text(AppStrings.addProfilePhoto));
      await tester.pumpAndSettle();
      expect(picker.calls, 1);
      expect(find.text(AppStrings.addProfilePhoto), findsOneWidget);
      expect(find.text(AppStrings.changeProfilePhoto), findsNothing);
    });

    testWidgets('previews the selected photo and uploads only on Save changes', (tester) async {
      final original = ImagePickerPlatform.instance;
      addTearDown(() => ImagePickerPlatform.instance = original);
      final bytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZE0AAAAASUVORK5CYII=');
      ImagePickerPlatform.instance = _TestPicker()..selection = XFile.fromData(bytes, name: 'avatar.png');
      final repository = _StubEditProfileRepository();
      final auth = _TestAuthViewModel()..emitCredentials(_credentials);
      await tester.pumpWidget(_wrap(auth, repository));
      await tester.tap(find.text(AppStrings.addProfilePhoto));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.changeProfilePhoto), findsOneWidget);
      expect(repository.savedPhoto, isNull);
      await tester.ensureVisible(find.text(AppStrings.editProfileSave));
      await tester.tap(find.text(AppStrings.editProfileSave));
      await tester.pumpAndSettle();
      expect(repository.savedPhoto?.bytes, bytes);
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
