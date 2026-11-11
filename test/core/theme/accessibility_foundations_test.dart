import 'dart:ui' show Tristate;

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/widgets/loading_view.dart';
import 'package:cherry_mvp/core/widgets/product_image_card.dart';
import 'package:cherry_mvp/core/widgets/star_rating.dart';
import 'package:cherry_mvp/features/home/widgets/bottom_nav_bar.dart';
import 'package:cherry_mvp/features/shared_widgets/bottom_cta.dart';
import 'package:cherry_mvp/features/shared_widgets/labeled_input_field.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Widget _app(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: buildTheme(brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

UserInformation _user(double rating) => UserInformation(
      username: 'u',
      location: 'l',
      reviewsCount: 0,
      followersCount: 0,
      followingCount: 0,
      rating: rating,
      awards: 0,
      hasBuyerDiscounts: false,
    );

void main() {
  group('theme contrast and target sizes', () {
    for (final brightness in Brightness.values) {
      test('filled buttons meet WCAG AA text contrast and 48dp height (${brightness.name})', () {
        final style = buildTheme(brightness).filledButtonTheme.style!;
        final background = style.backgroundColor!.resolve({})!;
        final foreground = style.foregroundColor!.resolve({})!;
        expect(_contrast(foreground, background), greaterThanOrEqualTo(4.5));
        expect(style.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(48));
      });

      test('outlined buttons and icon buttons are at least 48dp (${brightness.name})', () {
        final theme = buildTheme(brightness);
        expect(theme.outlinedButtonTheme.style!.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(48));
        final icon = theme.iconButtonTheme.style!.minimumSize!.resolve({})!;
        expect(icon.width, greaterThanOrEqualTo(48));
        expect(icon.height, greaterThanOrEqualTo(48));
      });
    }

    test('light outlined button text meets WCAG AA on the light surface', () {
      final theme = buildTheme();
      final foreground = theme.outlinedButtonTheme.style!.foregroundColor!.resolve({})!;
      expect(_contrast(foreground, theme.colorScheme.surface), greaterThanOrEqualTo(4.5));
    });

    test('primaryAction keeps white text above 4.5:1', () {
      expect(_contrast(Colors.white, AppColors.primaryAction), greaterThanOrEqualTo(4.5));
    });
  });

  group('BottomCta', () {
    testWidgets('meets tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(BottomCta(enabled: true, text: 'Continue', onPressed: () {})));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('announces the label and busy state while loading', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(BottomCta(enabled: true, loading: true, text: 'Continue', onPressed: () {})),
      );
      final semantics = tester.getSemantics(find.byType(FilledButton));
      expect(semantics.label, 'Continue, loading');
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });
  });

  group('LabeledInputField', () {
    testWidgets('exposes its label on the text field and meets tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          LabeledInputField(
            label: 'Email',
            hint: 'you@example.com',
            controller: controller,
            prefixIcon: Icons.mail,
            validator: (_) => 'Enter a valid email',
          ),
        ),
      );
      final field = tester.getSemantics(find.byType(EditableText));
      expect(field.flagsCollection.isTextField, isTrue);
      expect(field.label, startsWith('Email'));
      // The visible label must not be announced a second time on its own.
      expect(find.bySemanticsLabel(RegExp('^Email')), findsOneWidget);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      // Validation errors are exposed on the field itself.
      tester.state<FormFieldState<String>>(find.byType(TextFormField)).validate();
      await tester.pump();
      expect(tester.getSemantics(find.byType(EditableText)).hint, 'Enter a valid email');
      handle.dispose();
    });

    testWidgets('password visibility button meets 48dp guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(LabeledInputField(label: 'Password', controller: controller, obscureText: true)),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });
  });

  group('StarRating', () {
    testWidgets('announces one summary instead of individual stars', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(StarRating(userInformation: _user(4.5))));
      expect(find.bySemanticsLabel('4.5 out of 5 stars'), findsOneWidget);
      await tester.pumpWidget(_app(StarRating(userInformation: _user(3))));
      expect(find.bySemanticsLabel('3 out of 5 stars'), findsOneWidget);
      handle.dispose();
    });
  });

  group('LoadingView', () {
    testWidgets('announces a labelled live region', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const LoadingView()));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });
  });

  group('CherryBottomNavBar', () {
    // Darkest point of each background gradient in bottom_nav_bar.dart.
    const lightGradient = Color(0xFFFFC0D4);
    const darkGradient = Color(0xFF2E1A22);

    for (final brightness in Brightness.values) {
      testWidgets('tab labels meet WCAG AA contrast (${brightness.name})', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(brightness),
            home: Scaffold(
              bottomNavigationBar: CherryBottomNavBar(selectedIndex: 0, onItemSelected: (_) {}),
            ),
          ),
        );
        final bar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
        final background = brightness == Brightness.dark ? darkGradient : lightGradient;
        expect(_contrast(bar.selectedItemColor!, background), greaterThanOrEqualTo(4.5));
        expect(_contrast(bar.unselectedItemColor!, background), greaterThanOrEqualTo(4.5));
      });
    }

    testWidgets('tabs expose only their titles and meet tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            bottomNavigationBar: CherryBottomNavBar(selectedIndex: 0, onItemSelected: (_) {}),
          ),
        ),
      );
      for (final title in ['Home', 'Give', 'Profile']) {
        expect(find.bySemanticsLabel(RegExp('^$title')), findsOneWidget);
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('ProductImageCard like button', () {
    const product = Product(
      id: '1',
      name: 'Coat',
      description: 'd',
      quality: 'New',
      productImages: [],
      donation: 0,
      price: 1,
      securityFee: null,
      likes: 2,
      number: 1,
      size: 'M',
      postageSizeId: 'p',
    );

    testWidgets('is a labelled toggle with a 48dp target', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(const SizedBox(width: 200, height: 200, child: ProductImageCard(product: product))),
      );
      final finder = find.bySemanticsLabel('Like this item, 2 likes');
      expect(finder, findsOneWidget);
      expect(tester.getSemantics(finder).flagsCollection.isToggled, Tristate.isFalse);
      final size = tester.getSize(find.byType(GestureDetector).last);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await tester.tap(finder);
      await tester.pump();
      final liked = find.bySemanticsLabel('Like this item, 3 likes');
      expect(liked, findsOneWidget);
      expect(tester.getSemantics(liked).flagsCollection.isToggled, Tristate.isTrue);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
