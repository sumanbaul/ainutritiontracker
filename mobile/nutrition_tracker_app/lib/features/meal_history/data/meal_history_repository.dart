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
      required this.protein,
      required this.hasImage});
  final String id, name, type;
  final DateTime consumedAt;
  final double calories, protein;
  final bool hasImage;
  factory MealHistoryItem.fromJson(Map<String, dynamic> j) => MealHistoryItem(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? 'Meal',
      type: j['mealType'] as String,
      consumedAt: DateTime.parse(j['consumedAtUtc'] as String).toLocal(),
      calories: (j['totalCalories'] as num).toDouble(),
      protein: (j['totalProteinGrams'] as num).toDouble(),
      hasImage: j['hasImage'] as bool? ?? false);
}

class MealActivityDay {
  const MealActivityDay({
    required this.date,
    required this.startUtc,
    required this.endUtc,
    required this.mealCount,
    required this.calories,
    required this.targetCalories,
    required this.adherencePercent,
  });

  final DateTime date, startUtc, endUtc;
  final int mealCount;
  final double calories;
  final double? targetCalories, adherencePercent;

  factory MealActivityDay.fromJson(Map<String, dynamic> json) =>
      MealActivityDay(
        date: DateTime.parse(json['date'] as String),
        startUtc: DateTime.parse(json['startUtc'] as String).toUtc(),
        endUtc: DateTime.parse(json['endUtc'] as String).toUtc(),
        mealCount: json['mealCount'] as int,
        calories: (json['calories'] as num).toDouble(),
        targetCalories: (json['targetCalories'] as num?)?.toDouble(),
        adherencePercent: (json['adherencePercent'] as num?)?.toDouble(),
      );
}

class MealActivity {
  const MealActivity({
    required this.fromDate,
    required this.toDate,
    required this.timezone,
    required this.days,
  });

  final DateTime fromDate, toDate;
  final String timezone;
  final List<MealActivityDay> days;

  factory MealActivity.fromJson(Map<String, dynamic> json) => MealActivity(
        fromDate: DateTime.parse(json['fromDate'] as String),
        toDate: DateTime.parse(json['toDate'] as String),
        timezone: json['timezone'] as String,
        days: (json['days'] as List)
            .map((item) => MealActivityDay.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

final mealHistoryRepositoryProvider =
    Provider((ref) => MealHistoryRepository(ref.watch(apiClientProvider)));

class MealHistoryRepository {
  MealHistoryRepository(this._api);
  final ApiClient _api;
  Future<Result<List<MealHistoryItem>>> getAll() async {
    return _history('${ApiEndpoints.mealHistory}?take=100');
  }

  Future<Result<List<MealHistoryItem>>> getRange(
      DateTime startUtc, DateTime endUtc) async {
    final query = Uri(queryParameters: {
      'fromUtc': startUtc.toIso8601String(),
      'toUtc':
          endUtc.subtract(const Duration(microseconds: 1)).toIso8601String(),
      'take': '100',
    }).query;
    return _history('${ApiEndpoints.mealHistory}?$query');
  }

  Future<Result<MealActivity>> getActivity(
      DateTime fromDate, DateTime toDate) async {
    try {
      String date(DateTime value) =>
          '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      final query = Uri(queryParameters: {
        'fromDate': date(fromDate),
        'toDate': date(toDate),
      }).query;
      final response = await _api.get('${ApiEndpoints.mealActivity}?$query');
      return Success(MealActivity.fromJson(
          Map<String, dynamic>.from(response.data as Map)));
    } catch (_) {
      return const Failure(AppFailure('Meal activity could not be loaded.'));
    }
  }

  Future<Result<List<MealHistoryItem>>> _history(String path) async {
    try {
      final r = await _api.get(path);
      return Success((r.data as List)
          .map((x) =>
              MealHistoryItem.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList());
    } catch (_) {
      return const Failure(AppFailure('Meal history could not be loaded.'));
    }
  }
}
