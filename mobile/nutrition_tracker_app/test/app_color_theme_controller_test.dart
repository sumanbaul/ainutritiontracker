import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/app/theme/app_color_theme_controller.dart';
import 'package:nutrition_tracker_app/core/storage/secure_storage_service.dart';

void main() {
  test('color theme defaults to iOS Glass and persists a selected palette',
      () async {
    final storage = InMemorySecureStorageService();
    final controller = AppColorThemeController(storage);

    expect(controller.state, AppColorTheme.iosGlass);
    await controller.set(AppColorTheme.neonBlue);
    expect(await storage.read(AppColorThemeController.storageKey), 'neonBlue');

    final restored = AppColorThemeController(storage);
    await Future<void>.delayed(Duration.zero);
    expect(restored.state, AppColorTheme.neonBlue);
    controller.dispose();
    restored.dispose();
  });

  test('invalid stored palette safely falls back to iOS Glass', () async {
    final storage = InMemorySecureStorageService();
    await storage.write(AppColorThemeController.storageKey, 'not-a-theme');
    final controller = AppColorThemeController(storage);

    await Future<void>.delayed(Duration.zero);
    expect(controller.state, AppColorTheme.iosGlass);
    controller.dispose();
  });
}
