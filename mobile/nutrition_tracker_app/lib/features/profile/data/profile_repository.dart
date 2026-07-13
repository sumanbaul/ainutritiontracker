import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/local_database.dart';
import '../domain/profile.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository(
      ref.watch(apiClientProvider),
      ref.watch(localDatabaseProvider),
    ));

class ProfileRepository {
  ProfileRepository(this._api, this._database);
  final ApiClient _api;
  final LocalDatabase _database;
  Future<UserProfile?> getCached(String userId) async {
    final row = await (_database.select(_database.localProfiles)
          ..where((profile) => profile.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      return UserProfile.fromJson(
          Map<String, dynamic>.from(jsonDecode(row.payloadJson) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> _cache(String userId, Map<String, dynamic> json) =>
      _database.into(_database.localProfiles).insertOnConflictUpdate(
            LocalProfilesCompanion.insert(
              userId: userId,
              payloadJson: jsonEncode(json),
              updatedAt: DateTime.now().toUtc(),
              localUpdatedAt: DateTime.now().toUtc(),
            ),
          );
  Future<Result<UserProfile?>> get({String? userId}) async {
    try {
      final r = await _api.get('/api/profile');
      if (r.statusCode == 404) return const Success(null);
      final json = Map<String, dynamic>.from(r.data as Map);
      if (userId != null) await _cache(userId, json);
      return Success(UserProfile.fromJson(json));
    } catch (_) {
      return const Failure(AppFailure(
          'Profile sync failed. Check your connection and try again.'));
    }
  }

  Future<Result<UserProfile>> create(Map<String, dynamic> request) async {
    try {
      final r = await _api.post('/api/profile', data: request);
      return Success(
          UserProfile.fromJson(Map<String, dynamic>.from(r.data as Map)));
    } catch (_) {
      return const Failure(
          AppFailure('Could not generate your nutrition protocol.'));
    }
  }

  Future<Result<UserProfile>> update(Map<String, dynamic> request) async {
    try {
      final r = await _api.put('/api/profile', data: request);
      return Success(
          UserProfile.fromJson(Map<String, dynamic>.from(r.data as Map)));
    } catch (_) {
      return const Failure(AppFailure('Profile changes could not be saved.'));
    }
  }
}
