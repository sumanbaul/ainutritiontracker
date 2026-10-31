import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_color_theme_controller.dart';

abstract final class AppColors {
  static const canvas = Color(0xffF8F8F5),
      warmWhite = Color(0xffFFFDF8),
      ink = Color(0xff11110F),
      softInk = Color(0xff62625D),
      mist = Color(0xffEDEDE8),
      voidBlack = Color(0xff090A0D),
      midnight = Color(0xff111318),
      elevated = Color(0xff1A1D23),
      indigo = Color(0xff7067F0),
      violet = Color(0xff9B72F2),
      cyan = Color(0xff4AC7E8),
      blue = Color(0xff4A8EE8),
      pink = Color(0xffEF9CCB),
      green = Color(0xff79C900),
      warning = Color(0xffFFB24B),
      danger = Color(0xffF26868),
      primaryText = Color(0xffF8F8F5),
      secondaryText = Color(0xffA9ABB2),
      mutedText = Color(0xff73767F);
}

abstract final class AppGradients {
  static const primary = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xffBDEDF5), Color(0xffE9CEFF), Color(0xffFFD7D3)]);
  static const energy =
      LinearGradient(colors: [AppColors.cyan, AppColors.blue]);
  static const hero = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xff22252D), Color(0xff12151A), Color(0xff08090B)]);
  static const nutrition = LinearGradient(
      colors: [AppColors.warning, AppColors.green, AppColors.cyan]);
}

abstract final class AppTheme {
  static ThemeData dark([AppColorTheme palette = AppColorTheme.iosGlass]) =>
      _build(Brightness.dark, palette);
  static ThemeData light([AppColorTheme palette = AppColorTheme.iosGlass]) =>
      _build(Brightness.light, palette);

  static ThemeData _build(Brightness brightness, AppColorTheme palette) {
    final dark = brightness == Brightness.dark;
    final accent = AppPalette.accentFor(palette);
    final accentSoft = Color.lerp(accent, Colors.white, dark ? .16 : .78)!;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      surface: dark ? const Color(0xff0B0B12) : const Color(0xffFCFAFF),
    );
    final textTheme = ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: dark ? AppColors.primaryText : AppColors.ink,
          displayColor: dark ? AppColors.primaryText : AppColors.ink,
        );
    final foreground = dark ? AppColors.primaryText : AppColors.ink;
    final muted = dark ? AppColors.secondaryText : AppColors.softInk;
    final actionBackground = accent;
    final actionForeground = dark ? AppColors.ink : Colors.white;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      extensions: [
        AppSemanticColors(
          foreground: foreground,
          muted: muted,
          actionBackground: actionBackground,
          actionForeground: actionForeground,
          glassSurface: (dark ? const Color(0xff161621) : Colors.white)
              .withOpacity(dark ? .70 : .56),
          glassBorder:
              (dark ? Colors.white : accent).withOpacity(dark ? .16 : .18),
          destructive: AppColors.danger,
        ),
        AppPalette(
            theme: palette,
            accent: accent,
            accentSoft: accentSoft,
            pageTop: dark ? const Color(0xff14101E) : const Color(0xffF9F7FF),
            pageBottom:
                dark ? const Color(0xff050509) : const Color(0xffEEF0FF)),
      ],
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge
            ?.copyWith(fontWeight: FontWeight.w500, letterSpacing: -2.4),
        headlineLarge: textTheme.headlineLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.2),
        headlineMedium: textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.8),
        titleLarge: textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.35),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: (dark ? const Color(0xff171722) : Colors.white).withOpacity(.72),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: accent.withOpacity(dark ? .20 : .14))),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? AppColors.primaryText : AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? const Color(0xff191822).withOpacity(.88)
            : Colors.white.withOpacity(.66),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:
                BorderSide(color: accent.withOpacity(dark ? .20 : .16))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: accent, width: 1.4)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: actionForeground,
          backgroundColor: actionBackground,
          disabledBackgroundColor: dark ? Colors.white24 : Colors.black12,
          disabledForegroundColor: dark ? Colors.white38 : Colors.black38,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: foreground,
          side: BorderSide(color: foreground.withOpacity(.48)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: foreground),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: foreground),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? AppColors.elevated : AppColors.warmWhite,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: dark ? AppColors.elevated : AppColors.warmWhite,
        surfaceTintColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.foreground,
    required this.muted,
    required this.actionBackground,
    required this.actionForeground,
    required this.glassSurface,
    required this.glassBorder,
    required this.destructive,
  });

  final Color foreground;
  final Color muted;
  final Color actionBackground;
  final Color actionForeground;
  final Color glassSurface;
  final Color glassBorder;
  final Color destructive;

  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>()!;

  @override
  AppSemanticColors copyWith({
    Color? foreground,
    Color? muted,
    Color? actionBackground,
    Color? actionForeground,
    Color? glassSurface,
    Color? glassBorder,
    Color? destructive,
  }) =>
      AppSemanticColors(
        foreground: foreground ?? this.foreground,
        muted: muted ?? this.muted,
        actionBackground: actionBackground ?? this.actionBackground,
        actionForeground: actionForeground ?? this.actionForeground,
        glassSurface: glassSurface ?? this.glassSurface,
        glassBorder: glassBorder ?? this.glassBorder,
        destructive: destructive ?? this.destructive,
      );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      foreground: Color.lerp(foreground, other.foreground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      actionBackground:
          Color.lerp(actionBackground, other.actionBackground, t)!,
      actionForeground:
          Color.lerp(actionForeground, other.actionForeground, t)!,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
    );
  }
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.theme,
    required this.accent,
    required this.accentSoft,
    required this.pageTop,
    required this.pageBottom,
  });

  final AppColorTheme theme;
  final Color accent, accentSoft, pageTop, pageBottom;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  static Color accentFor(AppColorTheme theme) => switch (theme) {
        AppColorTheme.iosGlass => const Color(0xff7657FF),
        AppColorTheme.neonRed => const Color(0xffFF3D82),
        AppColorTheme.neonPurple => const Color(0xffBE5CFF),
        AppColorTheme.neonBlue => const Color(0xff00C8F8),
        AppColorTheme.neonGreen => const Color(0xff55E787),
        AppColorTheme.amoledGold => const Color(0xffFFC247),
      };

  @override
  AppPalette copyWith({
    AppColorTheme? theme,
    Color? accent,
    Color? accentSoft,
    Color? pageTop,
    Color? pageBottom,
  }) =>
      AppPalette(
          theme: theme ?? this.theme,
          accent: accent ?? this.accent,
          accentSoft: accentSoft ?? this.accentSoft,
          pageTop: pageTop ?? this.pageTop,
          pageBottom: pageBottom ?? this.pageBottom);

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
        theme: t < .5 ? theme : other.theme,
        accent: Color.lerp(accent, other.accent, t)!,
        accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
        pageTop: Color.lerp(pageTop, other.pageTop, t)!,
        pageBottom: Color.lerp(pageBottom, other.pageBottom, t)!);
  }
}
