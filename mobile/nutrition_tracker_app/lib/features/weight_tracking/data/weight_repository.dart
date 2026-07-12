import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/result/result.dart';

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

final weightRepositoryProvider =
    Provider((ref) => WeightRepository(ref.watch(apiClientProvider)));

class WeightRepository {
  WeightRepository(this._api);
  final ApiClient _api;
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
    try {
      final r = await _api.post(ApiEndpoints.weight, data: {
        'weightKg': kg,
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'notes': notes
      });
      return Success(
          WeightEntry.fromJson(Map<String, dynamic>.from(r.data as Map)));
    } catch (_) {
      return const Failure(AppFailure('Weight entry could not be saved.'));
    }
  }
}
