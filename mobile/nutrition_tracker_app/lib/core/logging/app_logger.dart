import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_config.dart';

final appLoggerProvider = Provider<AppLogger>(
    (ref) => AppLogger(config: ref.watch(appConfigProvider)));

class AppLogger {
  AppLogger({required this.config});
  final AppConfig config;
  void info(String message) {
    if (config.enableDiagnostics && kDebugMode) {
      debugPrint('[NutriLens] $message');
    }
  }

  void error(String message, Object error, StackTrace? stack) {
    if (kDebugMode) {
      debugPrint('[NutriLens] $message: $error');
    }
  }
}
