import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/result/result.dart';

class DashboardSummary {
  const DashboardSummary(
      {required this.date,
      required this.calories,
      required this.protein,
      required this.carbs,
      required this.fat,
      required this.fibre,
      required this.mealCount});
  final DateTime date;
  final double calories, protein, carbs, fat, fibre;
  final int mealCount;
  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
      date: DateTime.parse(j['summaryDate'] as String),
      calories: (j['totalCalories'] as num).toDouble(),
      protein: (j['totalProteinGrams'] as num).toDouble(),
      carbs: (j['totalCarbohydrateGrams'] as num).toDouble(),
      fat: (j['totalFatGrams'] as num).toDouble(),
      fibre: (j['totalFibreGrams'] as num).toDouble(),
      mealCount: j['mealCount'] as int);
}

final dashboardRepositoryProvider =
    Provider((ref) => DashboardRepository(ref.watch(apiClientProvider)));

class DashboardRepository {
  DashboardRepository(this._api);
  final ApiClient _api;
  Future<Result<DashboardSummary>> today() async {
    try {
      final r = await _api.get(ApiEndpoints.dashboardToday);
      return Success(
          DashboardSummary.fromJson(Map<String, dynamic>.from(r.data as Map)));
    } catch (_) {
      return const Failure(
          AppFailure('Daily nutrition data could not be loaded.'));
    }
  }
}
