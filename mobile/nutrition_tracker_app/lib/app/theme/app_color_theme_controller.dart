import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_storage_service.dart';

/// Named visual treatments from the NutriLens design language.
enum AppColorTheme {
  iosGlass,
  neonRed,
  neonPurple,
  neonBlue,
  neonGreen,
  amoledGold
}

extension AppColorThemeLabel on AppColorTheme {
  String get label => switch (this) {
        AppColorTheme.iosGlass => 'iOS Glass',
        AppColorTheme.neonRed => 'Neon Red',
        AppColorTheme.neonPurple => 'Neon Purple',
        AppColorTheme.neonBlue => 'Neon Blue',
        AppColorTheme.neonGreen => 'Neon Green',
        AppColorTheme.amoledGold => 'AMOLED Gold',
      };
}

final appColorThemeProvider =
    StateNotifierProvider<AppColorThemeController, AppColorTheme>(
        (ref) => AppColorThemeController(ref.watch(secureStorageProvider)));

class AppColorThemeController extends StateNotifier<AppColorTheme> {
  AppColorThemeController(this._storage) : super(AppColorTheme.iosGlass) {
    _load();
  }

  static const storageKey = 'nutrilens.color_theme';
  final SecureStorageService _storage;

  Future<void> _load() async {
    final saved = await _storage.read(storageKey);
    state = AppColorTheme.values
            .where((theme) => theme.name == saved)
            .firstOrNull ??
        AppColorTheme.iosGlass;
  }

  Future<void> set(AppColorTheme value) async {
    state = value;
    await _storage.write(storageKey, value.name);
  }

  Future<void> clear() async {
    state = AppColorTheme.iosGlass;
    await _storage.delete(storageKey);
  }
}
