import 'package:flutter/material.dart';
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
    return MaterialApp.router(
        title: 'NutriLens',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ref.watch(themeModeProvider),
        routerConfig: ref.watch(appRouterProvider));
  }
}
