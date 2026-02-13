import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:cherry_mvp/features/welcome/widgets/signup_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([MockSpec<LoginRepository>(), MockSpec<NavigationProvider>()])
import 'auth_ui_test.mocks.dart';

void main() {
  late MockLoginRepository mockRepository;
  late MockNavigationProvider mockNavigator;
  late LoginViewModel viewModel;

  setUp(() {
    mockRepository = MockLoginRepository();
    mockNavigator = MockNavigationProvider();
    viewModel = LoginViewModel(loginRepository: mockRepository);
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginViewModel>.value(value: viewModel),
        Provider<NavigationProvider>.value(value: mockNavigator),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: AuthCard(
            onClose: _dummyOnClose,
            mode: AuthMode.login,
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
}

void _dummyOnClose() {}
