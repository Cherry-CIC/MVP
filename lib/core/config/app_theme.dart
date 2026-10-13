import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTheme([Brightness brightness = Brightness.light]) {
  final isDark = brightness == Brightness.dark;

  var baseTheme = isDark
      ? ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121214),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xfff90653),
            onPrimary: Colors.white,
            primaryContainer: Color(0x33f90653),
            onPrimaryContainer: Color(0xFFFFB4C4),
            secondary: Color(0xFFA1A1AA),
            onSecondary: Colors.white,
            secondaryContainer: Color(0xFF27272A),
            onSecondaryContainer: Color(0xFFE4E4E7),
            surface: Color(0xFF18181B),
            surfaceContainer: Color(0xFF202024),
            surfaceContainerHighest: Color(0xFF27272A),
            onSurface: Color(0xFFF4F4F5),
            onSurfaceVariant: Color(0xFFA1A1AA),
            outline: Color(0xFF3F3F46),
            outlineVariant: Color(0xFF27272A),
            error: Color(0xFFFF5252),
            onError: Colors.white,
          ),
        )
      : ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.grey,
            brightness: Brightness.light,
            outline: const Color(0x1a8c8a8a),
            outlineVariant: const Color(0xfff3f3f3),
            primary: const Color(0xfff90653),
            onPrimary: Colors.white,
            primaryContainer: const Color(0x33f90653),
            onPrimaryContainer: Colors.black,
            secondary: const Color(0xff8c8a8a),
            onSecondary: Colors.black,
            secondaryContainer: const Color(0xfff1f1f1),
            surface: const Color(0xfffafafa),
            surfaceContainerHighest: const Color(0xfff1f1f1),
            onSurface: Colors.black,
            onSurfaceVariant: const Color(0xff707070),
          ),
        );

  TextTheme buildInstrumentTextTheme(TextTheme base) {
    final customBase = base.copyWith(
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: baseTheme.colorScheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: baseTheme.colorScheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: baseTheme.colorScheme.onSurface,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        color: baseTheme.colorScheme.onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: baseTheme.colorScheme.onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: baseTheme.colorScheme.onSurface,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: baseTheme.colorScheme.onSurface,
      ),
    );

    if (WidgetsBinding.instance is TestWidgetsFlutterBinding ||
        !GoogleFonts.config.allowRuntimeFetching) {
      return customBase;
    }

    try {
      return GoogleFonts.instrumentSansTextTheme(customBase);
    } catch (_) {
      return customBase;
    }
  }

  return baseTheme.copyWith(
    textTheme: buildInstrumentTextTheme(baseTheme.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: baseTheme.colorScheme.surface,
      foregroundColor: baseTheme.colorScheme.onSurface,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: baseTheme.colorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: baseTheme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? BorderSide(color: baseTheme.colorScheme.outlineVariant)
            : BorderSide.none,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: baseTheme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: baseTheme.colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: baseTheme.colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: baseTheme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(
      color: baseTheme.colorScheme.outlineVariant,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: baseTheme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? baseTheme.colorScheme.outline
              : baseTheme.colorScheme.secondary,
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor: baseTheme.colorScheme.surface,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: baseTheme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      hintStyle: TextStyle(color: baseTheme.colorScheme.onSurfaceVariant),
      prefixIconColor: baseTheme.colorScheme.onSurfaceVariant,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
        side: BorderSide(color: baseTheme.colorScheme.primary),
        foregroundColor:
            isDark ? Colors.white : baseTheme.colorScheme.primary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: baseTheme.colorScheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        foregroundColor: baseTheme.colorScheme.onPrimary,
      ),
    ),
  );
}
