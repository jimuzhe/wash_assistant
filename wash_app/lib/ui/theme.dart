import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildWasherTheme() {
  final scheme = FlexSchemeColor(
    primary: const Color(0xFF2C7BE5),
    primaryContainer: const Color(0xFFD6E4FF),
    secondary: const Color(0xFF38B2AC),
    secondaryContainer: const Color(0xFFC6F6F5),
    tertiary: const Color(0xFF805AD5),
    tertiaryContainer: const Color(0xFFE9D8FD),
    error: const Color(0xFFE53E3E),
  );

  return FlexThemeData.light(
    colors: scheme,
    surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
    blendLevel: 12,
    appBarStyle: FlexAppBarStyle.primary,
    useMaterial3: true,
    textTheme: GoogleFonts.notoSansTextTheme(),
  );
}
