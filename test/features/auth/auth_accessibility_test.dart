import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/auth/username_setup_page.dart';
import 'package:cherry_mvp/features/forgot_password/forgot_password_page.dart';
import 'package:cherry_mvp/features/forgot_password/forgot_password_repository.dart';
import 'package:cherry_mvp/features/forgot_password/forgot_password_viewmodel.dart';
import 'package:cherry_mvp/features/login/login_model.dart';
import 'package:cherry_mvp/features/login/login_page.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/features/register/register_model.dart';
import 'package:cherry_mvp/features/register/register_page.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:cherry_mvp/features/welcome/widgets/signup_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ConfigurableLoginRepository extends Fake implements LoginRepository {
  Completer<Result<UserCredentials?>>? pendingLogin;
  Result<UserCredentials?> nextResult = Result.failure('Invalid credentials');

  @override
  Future<Result<UserCredentials?>> login(LoginRequest request) {
    if (pendingLogin != null) return pendingLogin!.future;
    return Future.value(nextResult);
  }

  @override
  Future<Result<UserCredentials?>> signInWithSocial(SocialLoginType type) {
    if (pendingLogin != null) return pendingLogin!.future;
    return Future.value(nextResult);
  }
}

class _ConfigurableRegisterRepository extends Fake implements RegisterRepository {
  Completer<Result<UserCredentials?>>? pendingRegister;
  Result<UserCredentials?> nextResult = Result.failure('Email already in use');

  @override
  Future<Result<UserCredentials?>> register(RegisterRequest request) {
    if (pendingRegister != null) return pendingRegister!.future;
    return Future.value(nextResult);
  }
}

class _ConfigurableForgotPasswordRepository extends Fake implements ForgotPasswordRepository {
  Completer<Result<void>>? pendingReset;
  Result<void> nextResult = Result.failure('User not found');

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) {
    if (pendingReset != null) return pendingReset!.future;
    return Future.value(nextResult);
  }
}

Widget _wrapWithProviders(
  Widget child, {
  LoginRepository? loginRepo,
  RegisterRepository? registerRepo,
  ForgotPasswordRepository? forgotRepo,
  NavigationProvider? navigator,
}) {
  final nav = navigator ?? NavigationProvider();
  return MultiProvider(
    providers: [
      Provider<NavigationProvider>.value(value: nav),
      ChangeNotifierProvider<LoginViewModel>(
        create: (_) => LoginViewModel(
          loginRepository: loginRepo ?? _ConfigurableLoginRepository(),
          navigator: nav,
        ),
      ),
      ChangeNotifierProvider<RegisterViewModel>(
        create: (_) => RegisterViewModel(
          registerRepository: registerRepo ?? _ConfigurableRegisterRepository(),
          navigator: nav,
        ),
      ),
      ChangeNotifierProvider<ForgotPasswordViewModel>(
        create: (_) => ForgotPasswordViewModel(
          forgotPasswordRepository: forgotRepo ?? _ConfigurableForgotPasswordRepository(),
          navigator: nav,
        ),
      ),
    ],
    child: MaterialApp(
      theme: buildTheme(),
      home: child,
    ),
  );
}

void main() {
  group('WelcomePage & AuthCard accessibility', () {
    testWidgets('WelcomePage buttons meet tap target and label guidelines and isolate modal sheet', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrapWithProviders(const WelcomePage()));
      await tester.pumpAndSettle();

      // Background logo, tagline, Login, and Create Account are exposed; AuthCard is excluded while closed.
      expect(find.bySemanticsLabel(AppStrings.cherryLogo), findsOneWidget);
      expect(find.bySemanticsLabel(AppStrings.login), findsOneWidget);
      expect(find.bySemanticsLabel(AppStrings.createAccount), findsOneWidget);
      expect(find.bySemanticsLabel(AppStrings.continueWithGoogle), findsNothing);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      // Opening the bottom card excludes background buttons and exposes the sheet + dismiss backdrop.
      await tester.tap(find.bySemanticsLabel(AppStrings.createAccount));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(AppStrings.closeAuthMenu), findsOneWidget);
      expect(find.bySemanticsLabel(AppStrings.continueWithGoogle), findsOneWidget);
      expect(find.bySemanticsLabel(AppStrings.continueWithEmail), findsOneWidget);
      expect(find.byTooltip(AppStrings.close), findsOneWidget);
      // Background Create Account button is now excluded from semantics.
      expect(find.bySemanticsLabel(AppStrings.createAccount), findsNothing);

      // Tapping the close button closes the sheet and restores background semantics.
      await tester.tap(find.byTooltip(AppStrings.close));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(AppStrings.createAccount), findsOneWidget);
      handle.dispose();
    });

    testWidgets('AuthCard loading state announces Loading live region', (tester) async {
      final handle = tester.ensureSemantics();
      final repo = _ConfigurableLoginRepository()..pendingLogin = Completer<Result<UserCredentials?>>();
      await tester.pumpWidget(
        _wrapWithProviders(
          Scaffold(
            body: AuthCard(
              onClose: () {},
              mode: AuthMode.login,
            ),
          ),
          loginRepo: repo,
        ),
      );

      await tester.tap(find.text(AppStrings.continueWithGoogle));
      await tester.pump();

      expect(find.bySemanticsLabel(AppStrings.loading), findsOneWidget);
      handle.dispose();
    });
  });

  group('LoginPage accessibility', () {
    testWidgets('meets tap target and label guidelines, including back button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrapWithProviders(const LoginPage()));

      expect(find.byTooltip(AppStrings.back), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('announces loading state and liveRegion error on failed login', (tester) async {
      final handle = tester.ensureSemantics();
      final repo = _ConfigurableLoginRepository()..pendingLogin = Completer<Result<UserCredentials?>>();
      await tester.pumpWidget(_wrapWithProviders(const LoginPage(), loginRepo: repo));

      final context = tester.element(find.byType(LoginPage));
      final vm = Provider.of<LoginViewModel>(context, listen: false);

      unawaited(vm.login('user@example.com', 'password123'));
      await tester.pump();

      final loadingButton = find.bySemanticsLabel(AppStrings.loadingButton('Submit'));
      expect(loadingButton, findsOneWidget);
      expect(tester.getSemantics(loadingButton).flagsCollection.isEnabled, Tristate.isFalse);
      expect(tester.getSemantics(loadingButton).flagsCollection.isLiveRegion, isTrue);

      repo.pendingLogin!.complete(Result.failure('Invalid email or password'));
      await tester.pump();

      final errorNode = tester.getSemantics(find.text('Invalid email or password'));
      expect(errorNode.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

  group('RegisterPage accessibility', () {
    testWidgets('exposes labelled avatar picker, back button, and login link with >=48dp targets', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrapWithProviders(const RegisterPage()));

      expect(find.byTooltip(AppStrings.back), findsOneWidget);
      expect(find.bySemanticsLabel(AppStrings.uploadProfilePicture), findsOneWidget);
      expect(find.bySemanticsLabel(AppStrings.alreadyHaveAccountLogin), findsOneWidget);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('announces loading button and liveRegion on registration failure', (tester) async {
      final handle = tester.ensureSemantics();
      final repo = _ConfigurableRegisterRepository()..pendingRegister = Completer<Result<UserCredentials?>>();
      await tester.pumpWidget(_wrapWithProviders(const RegisterPage(), registerRepo: repo));

      final context = tester.element(find.byType(RegisterPage));
      final vm = Provider.of<RegisterViewModel>(context, listen: false);

      unawaited(vm.register('Alex', 'alex@example.com', 'alex', '07700900123', 'password123', null));
      await tester.pump();

      expect(find.bySemanticsLabel(AppStrings.loadingButton('Submit')), findsOneWidget);

      repo.pendingRegister!.complete(Result.failure('Username already taken'));
      await tester.pump();

      final errorNode = tester.getSemantics(find.text('Username already taken'));
      expect(errorNode.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

  group('ForgotPasswordPage & UsernameSetupPage accessibility', () {
    testWidgets('ForgotPasswordPage meets guidelines and announces loading/error states', (tester) async {
      final handle = tester.ensureSemantics();
      final repo = _ConfigurableForgotPasswordRepository()..pendingReset = Completer<Result<void>>();
      await tester.pumpWidget(_wrapWithProviders(const ForgotPasswordPage(), forgotRepo: repo));

      expect(find.byTooltip(AppStrings.back), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      final context = tester.element(find.byType(ForgotPasswordPage));
      final vm = Provider.of<ForgotPasswordViewModel>(context, listen: false);

      unawaited(vm.sendPasswordResetEmail('user@example.com'));
      await tester.pump();

      expect(find.bySemanticsLabel(AppStrings.loadingButton('Send Reset Email')), findsOneWidget);

      repo.pendingReset!.complete(Result.failure('Could not send reset email'));
      await tester.pump();

      final errorNode = tester.getSemantics(find.text('Could not send reset email'));
      expect(errorNode.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('UsernameSetupPage meets tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrapWithProviders(const UsernameSetupPage()));

      expect(find.byTooltip(AppStrings.back), findsOneWidget);
      final field = tester.getSemantics(find.byType(EditableText));
      expect(field.label, contains(AppStrings.usernameSetupHint));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
