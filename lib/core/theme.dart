import 'package:flutter/material.dart';

const ink = Color(0xFF111D49);
const blue = Color(0xFF1455F5);
const orange = Color(0xFFFF8B30);
const canvas = Color(0xFFF5F7FF);
const muted = Color(0xFF6B7595);
const line = Color(0xFFE5EAF7);
const green = Color(0xFF147D63);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Tajawal',
  scaffoldBackgroundColor: Colors.transparent,
  colorScheme: ColorScheme.fromSeed(
    seedColor: blue,
    primary: blue,
    secondary: orange,
    surface: Colors.white,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: ink,
      height: 1.35,
    ),
    headlineMedium: TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w700,
      color: ink,
      height: 1.4,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: ink,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: ink,
      height: 1.4,
    ),
    bodyLarge: TextStyle(fontSize: 17, color: ink, height: 1.65),
    bodyMedium: TextStyle(fontSize: 15, color: ink, height: 1.6),
    bodySmall: TextStyle(fontSize: 13, color: muted, height: 1.5),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: ink,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  dividerColor: line,
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: blue,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 54),
      textStyle: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 5,
      shadowColor: blue.withValues(alpha: .25),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 52),
      foregroundColor: blue,
      side: const BorderSide(color: line),
      textStyle: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: line),
    ),
  ),
);
