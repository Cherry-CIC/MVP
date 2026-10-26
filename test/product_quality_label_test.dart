import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/features/products/widgets/product_quality_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all quality greens are readable and progressively darker', () {
    var previous = 1.0;
    final background = const Color(0xFFFAFAFA).computeLuminance();
    for (final colour in ProductQualityLabel.colours.values) {
      final luminance = colour.computeLuminance();
      expect(luminance, lessThan(previous));
      expect((background + .05) / (luminance + .05), greaterThanOrEqualTo(4.5));
      previous = luminance;
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets('colours all categories and preserves labels in $brightness', (
      tester,
    ) async {
      final theme = buildTheme(brightness);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Column(
              children: [
                for (final category in ProductQualityLabel.colours.keys)
                  ProductQualityLabel(
                    ' ${category.toLowerCase()} ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const ProductQualityLabel('Unknown'),
                const ProductQualityLabel('6/Good'),
              ],
            ),
          ),
        ),
      );
      for (final entry in ProductQualityLabel.colours.entries) {
        final text = tester.widget<Text>(
          find.text(' ${entry.key.toLowerCase()} '),
        );
        expect(text.style!.color, entry.value);
        expect(text.style!.fontWeight, FontWeight.w800);
        expect(text.style!.fontSize, 18);
        expect(
          text.style!.backgroundColor,
          brightness == Brightness.dark ? const Color(0xFFFAFAFA) : null,
        );
      }
      for (final label in ['Unknown', '6/Good']) {
        final text = tester.widget<Text>(find.text(label));
        expect(text.style!.color, theme.colorScheme.onSurface);
        expect(text.style!.backgroundColor, isNull);
      }
    });
  }
}
