import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/local_database.dart';

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

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository(
    ref.watch(apiClientProvider), ref.watch(localDatabaseProvider)));

class DashboardRepository {
  DashboardRepository(this._api, this._database);
  final ApiClient _api;
  final LocalDatabase _database;
  Future<DashboardSummary?> cachedToday(String userId, DateTime date) async {
    final key = date.toIso8601String().substring(0, 10);
    final query = _database.select(_database.localDailySummaries)
      ..where((summary) => summary.userId.equals(userId))
      ..where((summary) => summary.summaryDate.equals(key));
    final row = await query.getSingleOrNull();
    return row == null
        ? null
        : DashboardSummary.fromJson(
            Map<String, dynamic>.from(jsonDecode(row.payloadJson) as Map));
  }

  Future<Result<DashboardSummary>> today({String? userId}) async {
    try {
      final r = await _api.get(ApiEndpoints.dashboardToday);
      final json = Map<String, dynamic>.from(r.data as Map);
      final summary = DashboardSummary.fromJson(json);
      if (userId != null) {
        await _database
            .into(_database.localDailySummaries)
            .insertOnConflictUpdate(LocalDailySummariesCompanion.insert(
                userId: userId,
                summaryDate: summary.date.toIso8601String().substring(0, 10),
                payloadJson: jsonEncode(json),
                updatedAt: DateTime.now().toUtc()));
      }
      return Success(summary);
    } catch (_) {
      return const Failure(
          AppFailure('Daily nutrition data could not be loaded.'));
    }
  }
}
