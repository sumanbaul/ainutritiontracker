import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';
import '../core/sync/offline_sync_service.dart';

class NutriLensApp extends ConsumerWidget {
  const NutriLensApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(offlineReplayProvider);
    final themeMode = ref.watch(themeModeProvider);
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
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: ref.watch(appRouterProvider),
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemStyle, child: child ?? const SizedBox.shrink()));
  }
}
