import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/features/login/widgets/login_form.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/register/widgets/register_form.dart';
import 'package:cherry_mvp/features/shared_widgets/labeled_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// These tests validate the forms without submitting authentication requests.
class _UnusedLoginRepository extends Fake implements LoginRepository {}

class _UnusedRegisterRepository extends Fake implements RegisterRepository {}

Widget _testApp(Widget form) {
  final navigator = NavigationProvider();
  return MultiProvider(
    providers: [
      Provider<NavigationProvider>.value(value: navigator),
      ChangeNotifierProvider<LoginViewModel>(
        create: (_) => LoginViewModel(loginRepository: _UnusedLoginRepository(), navigator: navigator),
      ),
      ChangeNotifierProvider<RegisterViewModel>(
        create: (_) => RegisterViewModel(registerRepository: _UnusedRegisterRepository(), navigator: navigator),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: form)),
  );
}

Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate((widget) => widget is LabeledInputField && widget.label == label),
  matching: find.byType(TextField),
);

Future<void> _enterText(WidgetTester tester, String label, String text) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_field(label), text);
}

Future<void> _toggle(WidgetTester tester, String tooltip) async {
  final button = find.byTooltip(tooltip);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets('Login retains the password and validation when visibility changes', (tester) async {
    await tester.pumpWidget(_testApp(const LoginForm()));

    expect(tester.widget<TextField>(_field('Password')).obscureText, isTrue);
    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(tester.widget<TextField>(_field('Email')).decoration!.suffixIcon, isNull);

    await _enterText(tester, 'Email', 'volunteer@example.com');
    await _enterText(tester, 'Password', 'short');
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);

    await _toggle(tester, 'Show password');
    expect(tester.widget<TextField>(_field('Password')).obscureText, isFalse);
    expect(tester.widget<TextField>(_field('Password')).controller!.text, 'short');
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(form.validate(), isFalse);

    await _enterText(tester, 'Password', 'Example password 123!');
    await _toggle(tester, 'Hide password');
    expect(tester.widget<TextField>(_field('Password')).obscureText, isTrue);
    expect(tester.widget<TextField>(_field('Password')).controller!.text, 'Example password 123!');
    expect(form.validate(), isTrue);
    await tester.pump();
    expect(find.text('Password must be at least 6 characters'), findsNothing);
  });

  testWidgets('Create Account toggles passwords independently and retains matching validation', (tester) async {
    await tester.pumpWidget(_testApp(const RegisterForm()));

    for (final label in ['Password', 'Confirm Password']) {
      expect(tester.widget<TextField>(_field(label)).obscureText, isTrue);
    }
    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(find.byTooltip('Show confirm password'), findsOneWidget);
    for (final label in ['Username', 'First Name', 'Email', 'Phone Number']) {
      expect(tester.widget<TextField>(_field(label)).decoration!.suffixIcon, isNull);
    }

    for (final entry in {
      'Username': 'volunteer',
      'First Name': 'Alex',
      'Email': 'volunteer@example.com',
      'Phone Number': '07700900123',
      'Password': 'Example password 123!',
      'Confirm Password': 'Different password 123!',
    }.entries) {
      await _enterText(tester, entry.key, entry.value);
    }
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);

    for (final (tooltip, passwordHidden, confirmationHidden) in [
      ('Show password', false, true),
      ('Show confirm password', false, false),
      ('Hide password', true, false),
      ('Hide confirm password', true, true),
    ]) {
      await _toggle(tester, tooltip);
      final password = tester.widget<TextField>(_field('Password'));
      final confirmation = tester.widget<TextField>(_field('Confirm Password'));
      expect(password.obscureText, passwordHidden);
      expect(confirmation.obscureText, confirmationHidden);
      expect(password.controller!.text, 'Example password 123!');
      expect(confirmation.controller!.text, 'Different password 123!');
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(form.validate(), isFalse);
    }

    await _enterText(tester, 'Confirm Password', 'Example password 123!');
    expect(form.validate(), isTrue);
    await tester.pump();
    expect(find.text('Passwords do not match'), findsNothing);
  });
}
