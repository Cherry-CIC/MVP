import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTheme([Brightness brightness = Brightness.light]) {
  var baseTheme = brightness == Brightness.light
      ? ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xfff90653),
            dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
            brightness: brightness,
            outline: const Color(0x1a8c8a8a),
            outlineVariant: Color(0xfff3f3f3),
            primary: const Color(0xfff90653),
            onPrimary: Colors.white,
            primaryContainer: Color(0x33f90653),
            onPrimaryContainer: Colors.black,
            secondary: const Color(0xff8c8a8a),
            onSecondary: Colors.black,
            tertiary: Color(0xff707070),
            onTertiary: Colors.white,
            surface: const Color(0xfffafafa),
            onSurface: Colors.black,
          ),
        )
      : ThemeData(
          brightness: brightness, colorSchemeSeed: const Color(0xfff90653));

  return baseTheme.copyWith(
    textTheme: GoogleFonts.instrumentSansTextTheme(baseTheme.textTheme),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: baseTheme.colorScheme.primary,
          )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: baseTheme.colorScheme.primary,
        foregroundColor: baseTheme.colorScheme.onPrimary,
      ),
    ),
  );
}
