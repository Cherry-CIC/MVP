import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/register/widgets/register_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class MockRegisterRepository extends Mock implements RegisterRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpRegisterForm(WidgetTester tester) async {
    final navigator = NavigationProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider<RegisterViewModel>(
            create: (_) => RegisterViewModel(
              registerRepository: MockRegisterRepository(),
              navigator: navigator,
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigator.navigatorKey,
          onGenerateRoute: AppRoutes.generateRoute,
          home: const Scaffold(body: RegisterForm()),
        ),
      ),
    );
  }

  testWidgets('requires legal acceptance before email registration', (tester) async {
    await pumpRegisterForm(tester);
    final submitButton = find.widgetWithText(FilledButton, 'Submit').first;
    await tester.scrollUntilVisible(
      submitButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);

    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text(AppStrings.legalAcceptanceRequiredText), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('opens both legal documents from registration', (tester) async {
    await pumpRegisterForm(tester);
    final termsLink = find.widgetWithText(TextButton, AppStrings.termsAndConditionsText).first;
    await tester.scrollUntilVisible(
      termsLink,
      500,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(termsLink);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.termsAndConditionsText), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.communityRulesText));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.communityRulesText), findsWidgets);
  });
}
