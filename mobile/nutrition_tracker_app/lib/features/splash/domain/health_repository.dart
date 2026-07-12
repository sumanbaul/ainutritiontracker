import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/result/result.dart';

enum HealthState { healthy, unhealthy, unreachable }

class HealthStatus {
  const HealthStatus(this.state, {this.message});
  final HealthState state;
  final String? message;
}

abstract interface class HealthRepository {
  Future<Result<HealthStatus>> checkLiveness();
  Future<Result<HealthStatus>> checkReadiness();
}

class ApiHealthRepository implements HealthRepository {
  ApiHealthRepository(this._client);
  final ApiClient _client;
  Future<Result<HealthStatus>> _check(String path) async {
    try {
      final response = await _client.getPlain(path);
      return Success(HealthStatus(response.statusCode == 200
          ? HealthState.healthy
          : HealthState.unhealthy));
    } on DioException catch (error) {
      final diagnostic =
          'type=${error.type}; message=${error.message}; error=${error.error}';
      if (kDebugMode) {
        debugPrint('NutriLens health check failed: $diagnostic');
      }
      return Failure(AppFailure(
          'Cannot reach the NutriLens server. Check that the backend is running and the API address is correct.',
          details: diagnostic));
    }
  }

  @override
  Future<Result<HealthStatus>> checkLiveness() => _check(ApiEndpoints.health);
  @override
  Future<Result<HealthStatus>> checkReadiness() =>
      _check(ApiEndpoints.readiness);
}
