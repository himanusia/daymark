import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class ItsTheDayPalette {
  static const ink = Color(0xFF0D1117);
  static const night = Color(0xFF121821);
  static const surface = Color(0xFF1A222D);
  static const surfaceElevated = Color(0xFF222D39);
  static const cloud = Color(0xFFF3F5F2);
  static const graphite = Color(0xFF1B252D);
  static const mint = Color(0xFFA9F4D0);
  static const mintStrong = Color(0xFF57D5A0);
  static const amber = Color(0xFFFFD28A);
  static const coral = Color(0xFFFF9A8B);
  static const muted = Color(0xFF98A7B6);
}

ThemeData itsthedayDarkTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: ItsTheDayPalette.mintStrong,
        brightness: Brightness.dark,
      ).copyWith(
        primary: ItsTheDayPalette.mint,
        onPrimary: ItsTheDayPalette.ink,
        secondary: ItsTheDayPalette.amber,
        onSecondary: ItsTheDayPalette.ink,
        error: ItsTheDayPalette.coral,
        onError: ItsTheDayPalette.ink,
        surface: ItsTheDayPalette.night,
        onSurface: ItsTheDayPalette.cloud,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: ItsTheDayPalette.ink,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ItsTheDayPalette.cloud,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ItsTheDayPalette.surface,
      hintStyle: const TextStyle(color: ItsTheDayPalette.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x332A3947)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: ItsTheDayPalette.mintStrong,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ItsTheDayPalette.mint,
        foregroundColor: ItsTheDayPalette.ink,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ItsTheDayPalette.cloud,
        side: const BorderSide(color: Color(0x665B7182)),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ItsTheDayPalette.surface,
      selectedColor: ItsTheDayPalette.mint,
      disabledColor: ItsTheDayPalette.surface,
      secondarySelectedColor: ItsTheDayPalette.mint,
      labelStyle: const TextStyle(color: ItsTheDayPalette.cloud),
      secondaryLabelStyle: const TextStyle(color: ItsTheDayPalette.ink),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: const BorderSide(color: Color(0x332A3947)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x223A4A59),
      space: 1,
      thickness: 1,
    ),
    textTheme: _textTheme(const Color(0xFFE9F0EB)),
  );
}

ThemeData itsthedayLightTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: ItsTheDayPalette.mintStrong,
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF087A5C),
        onPrimary: Colors.white,
        secondary: const Color(0xFF9A5B00),
        onSecondary: Colors.white,
        error: const Color(0xFFBA1A1A),
        surface: ItsTheDayPalette.cloud,
        onSurface: ItsTheDayPalette.graphite,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF6F8F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ItsTheDayPalette.graphite,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x18343F46)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF087A5C), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF087A5C),
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ItsTheDayPalette.graphite,
        side: const BorderSide(color: Color(0x55343F46)),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x1F343F46),
      space: 1,
      thickness: 1,
    ),
    textTheme: _textTheme(ItsTheDayPalette.graphite),
  );
}

TextTheme _textTheme(Color foreground) {
  return TextTheme(
    displayLarge: TextStyle(
      color: foreground,
      fontSize: 64,
      fontWeight: FontWeight.w700,
      letterSpacing: -2.4,
      height: 0.98,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    displayMedium: TextStyle(
      color: foreground,
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    headlineSmall: TextStyle(
      color: foreground,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      color: foreground,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      color: foreground,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: foreground, fontSize: 16, height: 1.4),
    bodyMedium: TextStyle(color: foreground, fontSize: 14, height: 1.35),
    labelLarge: TextStyle(
      color: foreground,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    ),
    labelMedium: TextStyle(
      color: foreground,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );
}
