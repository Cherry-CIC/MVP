import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/theme/theme_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppTheme Dark Mode Tests', () {
    test('buildTheme returns custom high-contrast dark color scheme for Brightness.dark', () {
      final darkTheme = buildTheme(Brightness.dark);

      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(darkTheme.scaffoldBackgroundColor, equals(const Color(0xFF121214)));

      final colorScheme = darkTheme.colorScheme;
      expect(colorScheme.primary, equals(const Color(0xFFF90653)));
      expect(colorScheme.onPrimary, equals(Colors.white));
      expect(colorScheme.surface, equals(const Color(0xFF18181B)));
      expect(colorScheme.onSurface, equals(const Color(0xFFF4F4F5)));
      expect(colorScheme.onSurfaceVariant, equals(const Color(0xFFA1A1AA)));
      expect(colorScheme.outline, equals(const Color(0xFF3F3F46)));
      expect(colorScheme.outlineVariant, equals(const Color(0xFF27272A)));

      expect(darkTheme.appBarTheme.backgroundColor, equals(const Color(0xFF18181B)));
      expect(darkTheme.appBarTheme.foregroundColor, equals(const Color(0xFFF4F4F5)));
      expect(darkTheme.cardTheme.color, equals(const Color(0xFF18181B)));
    });

    test('buildTheme returns expected light theme for Brightness.light', () {
      final lightTheme = buildTheme(Brightness.light);

      expect(lightTheme.brightness, equals(Brightness.light));
      expect(lightTheme.scaffoldBackgroundColor, equals(const Color(0xFFFAFAFA)));
      expect(lightTheme.colorScheme.primary, equals(const Color(0xFFF90653)));
    });

    testWidgets('AppColors.pinkBg returns dark mode container color when dark mode is active', (tester) async {
      late Color computedColor;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              computedColor = AppColors.pinkBg(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(computedColor, equals(const Color(0x33F90653)));
    });

    test('ThemeNotifier toggles between dark and light themes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeNotifier = ThemeNotifier(prefs);

      expect(themeNotifier.mode, equals(ThemeMode.system));

      themeNotifier.toggleDark(true);
      expect(themeNotifier.mode, equals(ThemeMode.dark));
      expect(themeNotifier.isDark, isTrue);

      themeNotifier.toggleDark(false);
      expect(themeNotifier.mode, equals(ThemeMode.light));
      expect(themeNotifier.isDark, isFalse);
    });
  });
}
