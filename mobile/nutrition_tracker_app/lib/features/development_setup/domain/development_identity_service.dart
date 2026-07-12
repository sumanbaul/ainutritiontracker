import '../../../app/config/app_config.dart';
import '../../../app/config/environment.dart';
import '../../../core/storage/secure_storage_service.dart';

abstract interface class IDevelopmentIdentityService {
  Future<String?> currentUserId();
  Future<void> saveUserId(String userId);
  Future<void> clearUserId();
  bool get isEnabled;
}

class DevelopmentIdentityService implements IDevelopmentIdentityService {
  DevelopmentIdentityService(this._config, this._storage);
  static const _key = 'nutrilens.development.user_id';
  final AppConfig _config;
  final SecureStorageService _storage;
  @override
  bool get isEnabled =>
      _config.enableDevelopmentIdentity &&
      _config.environment.allowsDevelopmentIdentity;
  @override
  Future<void> clearUserId() => _storage.delete(_key);
  @override
  Future<String?> currentUserId() async => isEnabled
      ? await _storage.read(_key) ??
          (_config.developmentUserId.isEmpty ? null : _config.developmentUserId)
      : null;
  @override
  Future<void> saveUserId(String userId) async {
    if (!isEnabled) throw StateError('Development identity is disabled.');
    await _storage.write(_key, userId.trim());
  }
}
