import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:cherry_mvp/features/welcome/widgets/signup_card.dart';

@GenerateNiceMocks([MockSpec<LoginRepository>(), MockSpec<NavigationProvider>()])
import 'auth_ui_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');
  final toastCalls = <MethodCall>[];

  late MockLoginRepository mockRepository;
  late MockNavigationProvider mockNavigator;
  late LoginViewModel viewModel;

  setUp(() {
    toastCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (call) async {
          toastCalls.add(call);
          return true;
        });
    mockRepository = MockLoginRepository();
    mockNavigator = MockNavigationProvider();
    viewModel = LoginViewModel(loginRepository: mockRepository, navigator: mockNavigator);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, null);
  });

  Widget createTestWidget({AuthMode mode = AuthMode.login}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginViewModel>.value(value: viewModel),
        Provider<NavigationProvider>.value(value: mockNavigator),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AuthCard(
            onClose: _dummyOnClose,
            mode: mode,
          ),
        ),
      ),
    );
  }

  testWidgets('AuthCard shows only allowed providers (Email, Google, Apple)', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Check for allowed providers
    expect(find.text(AppStrings.continueWithEmail), findsOneWidget);
    expect(find.text(AppStrings.continueWithGoogle), findsOneWidget);

    // Note: Apple only shows on iOS, so in a standard test environment (likely linux/mac),
    // it may or may not show depending on the Platform override.

    // STRICT REQUIREMENT: Facebook must NOT be present
    expect(find.textContaining('Facebook'), findsNothing);
    expect(find.textContaining('facebook'), findsNothing);
  });

  for (final mode in AuthMode.values) {
    testWidgets('AuthCard surfaces Google sign-in failure message in ${mode.name} mode', (
      WidgetTester tester,
    ) async {
      when(
        mockRepository.signInWithSocial(SocialLoginType.google),
      ).thenAnswer(
        (_) async => Result.failure('Google sign-in failed. Please try again.'),
      );

      await tester.pumpWidget(createTestWidget(mode: mode));
      await tester.tap(find.text(AppStrings.continueWithGoogle));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const Key('auth_card_error_message')), findsOneWidget);
      expect(
        find.text('Google sign-in failed. Please try again.'),
        findsOneWidget,
      );
      expect(toastCalls, hasLength(1));
      expect(toastCalls.single.method, 'showToast');
    });
  }
}

void _dummyOnClose() {}
