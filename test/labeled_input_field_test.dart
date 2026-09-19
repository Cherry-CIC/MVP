import 'package:cherry_mvp/features/shared_widgets/labeled_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildField(TextEditingController controller, {bool obscureText = true}) {
    return MaterialApp(
      home: Scaffold(
        body: LabeledInputField(
          label: 'Password',
          controller: controller,
          obscureText: obscureText,
          prefixIcon: Icons.lock,
          isLastField: true,
        ),
      ),
    );
  }

  testWidgets('visibility toggles preserve editing state and password keyboard protections', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildField(controller));

    final field = find.byType(EditableText);
    await tester.enterText(field, '  Test-\'password"  ');
    controller.selection = const TextSelection.collapsed(offset: 5);
    await tester.pump();
    final originalValue = controller.value;
    expect(tester.widget<EditableText>(field).obscureText, isTrue);
    expect(tester.testTextInput.setClientArgs!['enableIMEPersonalizedLearning'], isFalse);

    for (final visible in [true, false]) {
      await tester.tap(find.byTooltip(visible ? 'Show password' : 'Hide password'));
      await tester.pump();
      final editable = tester.widget<EditableText>(field);
      expect(editable.obscureText, !visible);
      expect(editable.autocorrect, isFalse);
      expect(editable.enableSuggestions, isFalse);
      expect(editable.enableIMEPersonalizedLearning, isFalse);
      expect(tester.testTextInput.setClientArgs!['enableIMEPersonalizedLearning'], isFalse);
      expect(editable.smartDashesType, SmartDashesType.disabled);
      expect(editable.smartQuotesType, SmartQuotesType.disabled);
      expect(editable.textInputAction, TextInputAction.done);
      expect(editable.focusNode.hasFocus, isTrue);
      expect(controller.value, originalValue);

      final label = visible ? 'Hide password' : 'Show password';
      final button = find.byTooltip(label);
      final size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(button),
        matchesSemantics(
          tooltip: label,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(find.byIcon(visible ? Icons.visibility_off : Icons.visibility), findsOneWidget);
    }
  });

  testWidgets('rebuilds retain visibility but a replacement password starts hidden', (tester) async {
    final controller = TextEditingController(text: 'Test password');
    final replacement = TextEditingController(text: 'Another password');
    addTearDown(controller.dispose);
    addTearDown(replacement.dispose);
    await tester.pumpWidget(buildField(controller));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    await tester.pumpWidget(buildField(controller));
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText, isFalse);

    await tester.pumpWidget(buildField(replacement));
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText, isTrue);
    expect(replacement.text, 'Another password');

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    await tester.pumpWidget(buildField(replacement, obscureText: false));
    expect(find.byType(IconButton), findsNothing);
    expect(tester.widget<EditableText>(find.byType(EditableText)).enableIMEPersonalizedLearning, isTrue);
    await tester.pumpWidget(buildField(replacement));
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText, isTrue);
  });
}
