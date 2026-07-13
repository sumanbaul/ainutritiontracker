import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../../../core/sync/offline_sync_service.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class WeightEntry {
  const WeightEntry(
      {required this.id,
      required this.weightKg,
      required this.recordedAtUtc,
      this.notes});
  final String id;
  final double weightKg;
  final DateTime recordedAtUtc;
  final String? notes;
  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
      id: j['id'] as String,
      weightKg: (j['weightKg'] as num).toDouble(),
      recordedAtUtc: DateTime.parse(j['recordedAtUtc'] as String).toUtc(),
      notes: j['notes'] as String?);
}

final weightRepositoryProvider = Provider((ref) => WeightRepository(
    ref.watch(apiClientProvider),
    ref.watch(offlineSyncProvider),
    () => currentUserScope(ref)));

class WeightRepository {
  WeightRepository(this._api, [this._sync, this._userScope]);
  final ApiClient _api;
  final OfflineSyncService? _sync;
  final Future<String?> Function()? _userScope;
  Future<Result<List<WeightEntry>>> getAll() async {
    try {
      final r = await _api.get('${ApiEndpoints.weight}?take=100');
      return Success((r.data as List)
          .map((x) => WeightEntry.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList());
    } catch (_) {
      return const Failure(AppFailure('Weight history could not be loaded.'));
    }
  }

  Future<Result<WeightEntry>> add(double kg, String? notes) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final payload = {
      'weightKg': kg,
      'recordedAtUtc': now.toIso8601String(),
      'notes': notes,
      'clientOperationId': id
    };
    try {
      final r = await _api.post(ApiEndpoints.weight, data: payload);
      return Success(
          WeightEntry.fromJson(Map<String, dynamic>.from(r.data as Map)));
    } on DioException catch (error) {
      final user = await _userScope?.call();
      if (error.response == null && user != null && _sync != null) {
        await _sync.enqueue(
            userId: user,
            operation: 'create',
            entityType: 'weight',
            entityId: id,
            payload: {
              '_path': ApiEndpoints.weight,
              '_method': 'POST',
              ...payload
            });
        return Success(WeightEntry(
            id: id, weightKg: kg, recordedAtUtc: now, notes: notes));
      }
      return const Failure(AppFailure('Weight entry could not be saved.'));
    }
  }
}
