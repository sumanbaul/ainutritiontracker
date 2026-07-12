import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'core/logging/app_logger.dart';

Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final config = AppConfig.fromDefines();
      final logger = AppLogger(config: config);
      FlutterError.onError = (details) {
        logger.error(
            'Flutter framework error', details.exception, details.stack);
        FlutterError.presentError(details);
      };
      runApp(ProviderScope(overrides: [
        appConfigProvider.overrideWithValue(config),
        appLoggerProvider.overrideWithValue(logger)
      ], child: const NutriLensApp()));
    },
    (error, stack) => AppLogger(config: AppConfig.fromDefines())
        .error('Uncaught asynchronous error', error, stack),
  );
}
