import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_config.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/storage/local_database.dart';

final mealVisionSettingsRepositoryProvider = Provider((ref) =>
    MealVisionSettingsRepository(ref.watch(apiClientProvider),
        ref.watch(localDatabaseProvider), ref.watch(appConfigProvider)));

class MealVisionSelection {
  const MealVisionSelection(this.providerId, this.modelId);
  final String providerId;
  final String modelId;
}

class MealVisionCapability {
  MealVisionCapability(this.id, this.displayName, this.isLocal,
      this.isAvailable, this.unavailableReason, this.models);
  factory MealVisionCapability.fromJson(Map<String, dynamic> json) =>
      MealVisionCapability(
          json['id'] as String,
          json['displayName'] as String,
          json['isLocal'] as bool,
          json['isAvailable'] as bool,
          json['unavailableReason'] as String?,
          (json['models'] as List)
              .map((x) =>
                  MealVisionModel.fromJson(Map<String, dynamic>.from(x as Map)))
              .toList());
  final String id, displayName;
  final bool isLocal, isAvailable;
  final String? unavailableReason;
  final List<MealVisionModel> models;
}

class MealVisionModel {
  MealVisionModel(this.id, this.displayName, this.isDefault);
  factory MealVisionModel.fromJson(Map<String, dynamic> json) =>
      MealVisionModel(json['id'] as String, json['displayName'] as String,
          json['isDefault'] as bool);
  final String id, displayName;
  final bool isDefault;
}

class MealVisionSettingsRepository {
  MealVisionSettingsRepository(this._api, this._database, this._config);
  final ApiClient _api;
  final LocalDatabase _database;
  final AppConfig _config;
  String get _key => 'nutrilens.ai.selection.${_config.developmentUserId}';
  Future<List<MealVisionCapability>> capabilities() async {
    final response = await _api.get('/api/meal-vision/capabilities');
    return (response.data as List)
        .map((x) =>
            MealVisionCapability.fromJson(Map<String, dynamic>.from(x as Map)))
        .toList();
  }

  Future<MealVisionSelection?> selected() async {
    final raw = await _database.readSetting(_key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return MealVisionSelection(
        json['providerId'] as String, json['modelId'] as String);
  }

  Future<void> save(MealVisionSelection selection) => _database.saveSetting(
      _key,
      jsonEncode(
          {'providerId': selection.providerId, 'modelId': selection.modelId}));
}
