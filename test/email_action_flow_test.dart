// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/services/firebase_auth_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/forgot_password/forgot_password_repository.dart';
import 'package:cherry_mvp/features/forgot_password/forgot_password_viewmodel.dart';
import 'package:cherry_mvp/features/login/login_page.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/features/register/register_model.dart';
import 'package:cherry_mvp/features/register/register_page.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/register/verify_email_page.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:cherry_mvp/features/welcome/widgets/post_auth_username_gate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/unexpected_api_service.dart';

const _email = 'alex@example.com';

class _User extends Fake implements User {
  @override
  final String uid;
  @override
  bool emailVerified = false;
  final reloadResult = Completer<void>();
  final sendResult = Completer<void>();
  int sends = 0;
  int reloads = 0;

  _User(this.uid);

  @override
  Future<void> reload() {
    reloads++;
    return reloadResult.future;
  }

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? settings]) {
    sends++;
    return sendResult.future;
  }
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? currentUser;
  final changes = StreamController<User?>.broadcast();
  String? resetError;
  String? resetAddress;

  @override
  Stream<User?> authStateChanges() async* {
    yield currentUser;
    yield* changes.stream;
  }

  @override
  Stream<User?> userChanges() => authStateChanges();

  void changeUser(User? user) {
    currentUser = user;
    changes.add(user);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email, ActionCodeSettings? actionCodeSettings}) async {
    resetAddress = email;
    if (resetError != null) throw FirebaseAuthException(code: resetError!);
  }
}

class _Registration extends Fake implements RegisterRepository {
  final _Auth auth;
  final user = _User('new-account');
  final profile = Completer<Result<UserCredentials?>>();

  _Registration(this.auth);

  @override
  Future<Result<UserCredentials?>> register(RegisterRequest request) {
    auth.changeUser(user);
    return profile.future;
  }
}

class _Login extends Fake implements LoginRepository {
  final _Auth auth;
  _Login(this.auth);

  @override
  Future<Result<void>> logout() async {
    auth.changeUser(null);
    return Result.success(null);
  }
}

class _Firestore extends Fake implements FirebaseFirestore {}

class _Harness {
  final auth = _Auth();
  final nav = NavigationProvider();
  late final service = FirebaseAuthService(firebaseAuth: auth);
  late final registration = _Registration(auth);
  late final login = _Login(auth);
  int usernameLookups = 0;

  Future<void> pump(WidgetTester tester) async {
    addTearDown(auth.changes.close);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: nav),
          Provider<FirebaseAuth>.value(value: auth),
          Provider<FirebaseAuthService>.value(value: service),
          ChangeNotifierProvider(
            create: (_) => LoginViewModel(loginRepository: login, navigator: nav),
          ),
          ChangeNotifierProvider(
            create: (_) => RegisterViewModel(registerRepository: registration, navigator: nav),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                ForgotPasswordViewModel(forgotPasswordRepository: ForgotPasswordRepository(service), navigator: nav),
          ),
          ChangeNotifierProvider(
            create: (_) => AuthViewModel(
              loginRepository: login,
              navigator: nav,
              firebaseAuth: auth,
              firestore: _Firestore(),
              apiService: const UnexpectedApiService(),
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: nav.navigatorKey,
          onGenerateRoute: AppRoutes.generateRoute,
          home: StreamBuilder<User?>(
            stream: auth.userChanges(),
            builder: (_, snapshot) => snapshot.data == null
                ? const WelcomePage()
                : PostAuthUsernameGate(
                    firebaseAuth: auth,
                    usernameResolver: (_) async {
                      usernameLookups++;
                      return Result.success('alex');
                    },
                    homeBuilder: (_) => const Scaffold(body: Text('Home')),
                  ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submitForm(WidgetTester tester, {bool fromLogin = false}) async {
    await tester.tap(find.text(fromLogin ? AppStrings.login : AppStrings.createAccount).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.continueWithEmail));
    await tester.pumpAndSettle();
    if (fromLogin) {
      final create = find.textContaining(RegExp('^Create ', caseSensitive: false));
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
    }
    final fields = find.byType(TextFormField);
    const values = ['alex', 'Alex', _email, '07123456789', 'password123', 'password123'];
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(fields.at(i), values[i]);
    }
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(find.byType(VerifyEmailPage), findsNothing);
    expect(usernameLookups, 0);
  }

  Future<void> completeProfile(WidgetTester tester) async {
    registration.profile.complete(Result.success(UserCredentials(uid: registration.user.uid, email: _email)));
    await tester.pumpAndSettle();
    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text(_email), findsOneWidget);
    expect(find.byType(RegisterPage, skipOffstage: false), findsNothing);
    expect(usernameLookups, 0);
    expect(registration.user.sends, 0);
  }
}

void main() {
  for (final fromLogin in [false, true]) {
    testWidgets('sign up via ${fromLogin ? 'login' : 'welcome'} and skip once', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.submitForm(tester, fromLogin: fromLogin);
      await h.completeProfile(tester);
      if (fromLogin) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.text('Continue for now'));
      }
      await tester.pumpAndSettle();
      expect(h.registration.user.emailVerified, isFalse);
      expect(find.text('Home'), findsOneWidget);
      expect(h.nav.navigatorKey.currentState!.canPop(), isFalse);
      expect(h.usernameLookups, 1);
      h.auth.changeUser(null);
      await tester.pumpAndSettle();
      h.auth.changeUser(h.registration.user);
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(VerifyEmailPage), findsNothing);
    });
  }

  testWidgets('failed profile creation keeps the registration form', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.submitForm(tester);
    h.registration.profile.complete(Result.failure('Unable to save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to save profile'), findsOneWidget);
    expect(find.byType(RegisterPage), findsOneWidget);
    expect(find.byType(VerifyEmailPage), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(RegisterPage), findsNothing);
    expect(h.nav.navigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets('resume reloads Firebase and continues once when verified', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.submitForm(tester);
    await h.completeProfile(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(h.registration.user.reloads, 1);
    h.registration.user.emailVerified = true;
    h.registration.user.reloadResult.complete();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(h.usernameLookups, 1);
  });

  for (final resendFails in [false, true]) {
    testWidgets('resend is debounced and reports ${resendFails ? 'failure' : 'acceptance'}', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.submitForm(tester);
      await h.completeProfile(tester);
      await tester.tap(find.text('Resend verification email'));
      await tester.tap(find.text('Resend verification email'));
      expect(h.registration.user.sends, 1);
      if (resendFails) {
        h.registration.user.sendResult.completeError(FirebaseAuthException(code: 'too-many-requests'));
      } else {
        h.registration.user.sendResult.complete();
      }
      await tester.pumpAndSettle();
      expect(find.textContaining(resendFails ? 'Unable to resend' : 'Verification email sent.'), findsOneWidget);
      await tester.tap(find.text('I’ve verified my email'));
      if (resendFails) {
        h.registration.user.reloadResult.completeError(FirebaseAuthException(code: 'network-request-failed'));
      } else {
        h.registration.user.reloadResult.complete();
      }
      await tester.pumpAndSettle();
      expect(find.textContaining(resendFails ? 'Unable to check' : 'still unverified'), findsOneWidget);
      await tester.tap(find.text('Continue for now'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  }

  testWidgets('a late verification cannot pop another route after skipping', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.submitForm(tester);
    await h.completeProfile(tester);
    await tester.tap(find.text('I’ve verified my email'));
    await tester.tap(find.text('Continue for now'));
    unawaited(h.nav.navigateTo(AppRoutes.login));
    h.registration.user.emailVerified = true;
    h.registration.user.reloadResult.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('switching accounts dismisses the prompt while a reload is pending', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.submitForm(tester);
    await h.completeProfile(tester);
    await tester.tap(find.text('I’ve verified my email'));
    h.auth.changeUser(_User('another-account')..emailVerified = true);
    await tester.pumpAndSettle();
    h.registration.user.reloadResult.complete();
    await tester.pumpAndSettle();
    expect(find.byType(VerifyEmailPage), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(h.usernameLookups, 1);
  });

  testWidgets('wrong address signs out and a late reload cannot reopen the app', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.submitForm(tester);
    await h.completeProfile(tester);
    await tester.tap(find.text('I’ve verified my email'));
    await tester.ensureVisible(find.text('Sign out and return to login'));
    await tester.tap(find.text('Sign out and return to login'));
    await tester.pumpAndSettle();
    h.registration.user.reloadResult.complete();
    await tester.pumpAndSettle();
    expect(h.auth.currentUser, isNull);
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(h.nav.navigatorKey.currentState!.canPop(), isFalse);
    expect(h.usernameLookups, 0);
  });

  testWidgets('reset can retry, confirms the submitted address and returns to email login', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    unawaited(h.nav.navigateTo(AppRoutes.login));
    await tester.pumpAndSettle();
    final forgot = find.text(AppStrings.forgotPassword);
    await tester.ensureVisible(forgot);
    await tester.tap(forgot);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '  $_email  ');
    h.auth.resetError = 'network-request-failed';
    await tester.tap(find.text('Send Reset Email'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Please try again'), findsOneWidget);
    expect(find.text('Check your email'), findsNothing);
    h.auth.resetError = null;
    await tester.tap(find.text('Send Reset Email'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 1));
    expect(h.auth.resetAddress, _email);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text(_email), findsOneWidget);
    expect(find.text('Continue for now'), findsNothing);
    await tester.tap(find.text('Back to login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });

  test('account-specific reset responses stay neutral, throttling remains retryable', () async {
    final h = _Harness();
    for (final code in ['user-not-found', 'user-disabled']) {
      h.auth.resetError = code;
      expect((await h.service.sendPasswordResetEmail(_email)).isSuccess, isTrue);
    }
    h.auth.resetError = 'too-many-requests';
    expect((await h.service.sendPasswordResetEmail(_email)).isSuccess, isFalse);
  });
}
