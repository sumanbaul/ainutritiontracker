import 'package:flutter/material.dart';

abstract final class AppColors {
  static const voidBlack = Color(0xff070A12),
      midnight = Color(0xff0D1220),
      elevated = Color(0xff141A2C),
      indigo = Color(0xff5B5CFF),
      violet = Color(0xff8B5CF6),
      cyan = Color(0xff16E0FF),
      blue = Color(0xff3B82F6),
      pink = Color(0xffFF4FD8),
      green = Color(0xff55F991),
      primaryText = Color(0xffF4F7FF);
}

abstract final class AppGradients {
  static const primary =
      LinearGradient(colors: [AppColors.indigo, AppColors.violet]);
  static const energy =
      LinearGradient(colors: [AppColors.cyan, AppColors.blue]);
}

abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);
  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
        seedColor: AppColors.indigo, brightness: brightness);
    return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor:
            isDark ? AppColors.voidBlack : const Color(0xfff5f7ff),
        cardTheme: CardTheme(
            color: isDark ? AppColors.elevated : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22))),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.indigo,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)))));
  }
}
