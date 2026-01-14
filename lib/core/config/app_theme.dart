import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTheme([Brightness brightness = Brightness.light]) {
  var baseTheme = brightness == Brightness.light
      ? ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.grey,
            brightness: brightness,
            outline: const Color(0x1a8c8a8a),
            outlineVariant: Color(0xfff3f3f3),
            primary: const Color(0xfff90653),
            onPrimary: Colors.white,
            primaryContainer: Color(0x33f90653),
            onPrimaryContainer: Colors.black,
            secondary: const Color(0xff8c8a8a),
            onSecondary: Colors.black,
            secondaryContainer: const Color(0xfff1f1f1),
            surface: const Color(0xfffafafa),
            surfaceContainerHighest: const Color(0xfff1f1f1),
            onSurface: Colors.black,
            onSurfaceVariant: const Color(0xff707070),
          ),
        )
      : ThemeData(
          brightness: brightness,
          colorSchemeSeed: const Color(0xfff90653),
        );

  return baseTheme.copyWith(
    textTheme: GoogleFonts.instrumentSansTextTheme(
      baseTheme.textTheme.copyWith(
        titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: baseTheme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: baseTheme.colorScheme.surface,
      centerTitle: true,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: baseTheme.colorScheme.secondary,
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor: baseTheme.colorScheme.surface,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: baseTheme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      hintStyle: TextStyle(color: baseTheme.colorScheme.secondary),
      prefixIconColor: baseTheme.colorScheme.secondary,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: TextStyle(fontWeight: FontWeight.w500),
        side: BorderSide(color: baseTheme.colorScheme.primary),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: baseTheme.colorScheme.primary,
        textStyle: TextStyle(fontWeight: FontWeight.w600),
        foregroundColor: baseTheme.colorScheme.onPrimary,
      ),
    ),
  );
}
