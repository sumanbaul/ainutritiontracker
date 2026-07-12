import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/profile.dart';

final profileRepositoryProvider =
    Provider((ref) => ProfileRepository(ref.watch(apiClientProvider)));

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;
  Future<Result<UserProfile?>> get() async {
    try {
      final r = await _api.get('/api/profile');
      if (r.statusCode == 404) return const Success(null);
      return Success(
          UserProfile.fromJson(Map<String, dynamic>.from(r.data as Map)));
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
