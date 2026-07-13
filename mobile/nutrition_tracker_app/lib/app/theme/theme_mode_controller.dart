import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage_service.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
    (ref) => ThemeModeController(ref.watch(secureStorageProvider)));

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._storage) : super(ThemeMode.system) {
    _load();
  }
  final SecureStorageService _storage;
  static const _key = 'nutrilens.theme_mode';
  Future<void> _load() async {
    final saved = await _storage.read(_key);
    state = ThemeMode.values.where((x) => x.name == saved).firstOrNull ??
        ThemeMode.system;
  }

  Future<void> set(ThemeMode value) async {
    state = value;
    await _storage.write(_key, value.name);
  }
}
