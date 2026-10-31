import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/app_color_theme_controller.dart';
import 'theme/theme_mode_controller.dart';
import '../core/sync/offline_sync_service.dart';

class NutriLensApp extends ConsumerWidget {
  const NutriLensApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(offlineReplayProvider);
    final themeMode = ref.watch(themeModeProvider);
    final palette = ref.watch(appColorThemeProvider);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final brightness = themeMode == ThemeMode.system
        ? platformBrightness
        : themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light;
    final dark = brightness == Brightness.dark;
    final systemStyle =
        (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: dark ? AppColors.voidBlack : AppColors.canvas,
      systemNavigationBarDividerColor:
          dark ? AppColors.voidBlack : AppColors.canvas,
      systemNavigationBarContrastEnforced: false,
    );
    return MaterialApp.router(
        title: 'NutriLens',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(palette),
        darkTheme: AppTheme.dark(palette),
        themeMode: themeMode,
        routerConfig: ref.watch(appRouterProvider),
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemStyle,
            child:
                GlassAppBackground(child: child ?? const SizedBox.shrink())));
  }
}

class GlassAppBackground extends StatelessWidget {
  const GlassAppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.pageTop, palette.pageBottom]),
      ),
      child: Stack(children: [
        Positioned(
            top: -150,
            right: -100,
            child: _Glow(color: palette.accentSoft, size: 360)),
        Positioned(
            top: 320,
            left: -180,
            child: _Glow(color: palette.accent.withOpacity(.13), size: 360)),
        child,
      ]),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)));
}
