import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/result/result.dart';

class MealHistoryItem {
  const MealHistoryItem(
      {required this.id,
      required this.name,
      required this.type,
      required this.consumedAt,
      required this.calories,
      required this.protein});
  final String id, name, type;
  final DateTime consumedAt;
  final double calories, protein;
  factory MealHistoryItem.fromJson(Map<String, dynamic> j) => MealHistoryItem(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? 'Meal',
      type: j['mealType'] as String,
      consumedAt: DateTime.parse(j['consumedAtUtc'] as String).toLocal(),
      calories: (j['totalCalories'] as num).toDouble(),
      protein: (j['totalProteinGrams'] as num).toDouble());
}

final mealHistoryRepositoryProvider =
    Provider((ref) => MealHistoryRepository(ref.watch(apiClientProvider)));

class MealHistoryRepository {
  MealHistoryRepository(this._api);
  final ApiClient _api;
  Future<Result<List<MealHistoryItem>>> getAll() async {
    try {
      final r = await _api.get('${ApiEndpoints.mealHistory}?take=100');
      return Success((r.data as List)
          .map((x) =>
              MealHistoryItem.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList());
    } catch (_) {
      return const Failure(AppFailure('Meal history could not be loaded.'));
    }
  }
}
