import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/result/result.dart';

final habitRepositoryProvider =
    Provider((ref) => HabitRepository(ref.watch(apiClientProvider)));

class HabitDay {
  const HabitDay(this.date, this.calories, this.meals);
  final DateTime date;
  final double calories;
  final int meals;

  factory HabitDay.fromJson(Map<String, dynamic> json) => HabitDay(
        DateTime.parse(json['date'] as String),
        (json['calories'] as num).toDouble(),
        json['meals'] as int,
      );
}

class HabitSummary {
  const HabitSummary({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.totalCalories,
    required this.averageCalories,
    required this.confirmedMeals,
    required this.hydrationMillilitres,
    required this.fastingMinutes,
    this.targetCalories,
    this.calorieAdherencePercent,
    this.currentWeightKg,
    this.weightChangeKg,
  });

  final String period;
  final DateTime startDate, endDate;
  final List<HabitDay> days;
  final double totalCalories, averageCalories, hydrationMillilitres;
  final int confirmedMeals, fastingMinutes;
  final double? targetCalories, calorieAdherencePercent;
  final double? currentWeightKg, weightChangeKg;

  factory HabitSummary.fromJson(Map<String, dynamic> json) => HabitSummary(
        period: json['period'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        days: (json['days'] as List)
            .map((value) =>
                HabitDay.fromJson(Map<String, dynamic>.from(value as Map)))
            .toList(),
        totalCalories: (json['totalCalories'] as num).toDouble(),
        averageCalories: (json['averageCalories'] as num).toDouble(),
        confirmedMeals: json['confirmedMeals'] as int,
        hydrationMillilitres: (json['hydrationMillilitres'] as num).toDouble(),
        fastingMinutes: json['fastingMinutes'] as int,
        targetCalories: (json['targetCalories'] as num?)?.toDouble(),
        calorieAdherencePercent:
            (json['calorieAdherencePercent'] as num?)?.toDouble(),
        currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble(),
        weightChangeKg: (json['weightChangeKg'] as num?)?.toDouble(),
      );
}

class HabitReminder {
  const HabitReminder({
    required this.id,
    required this.type,
    required this.localTime,
    required this.timezone,
    required this.isEnabled,
  });
  final String id, type, timezone;
  final String localTime;
  final bool isEnabled;

  factory HabitReminder.fromJson(Map<String, dynamic> json) => HabitReminder(
        id: json['id'] as String,
        type: json['type'] as String,
        localTime: json['localTime'] as String,
        timezone: json['timezone'] as String,
        isEnabled: json['isEnabled'] as bool,
      );
}

class HabitRepository {
  HabitRepository(this._api);
  final ApiClient _api;

  Future<Result<HabitSummary>> summary(String period) async {
    try {
      final response =
          await _api.get('${ApiEndpoints.habitSummary}?period=$period');
      return Success(HabitSummary.fromJson(
          Map<String, dynamic>.from(response.data as Map)));
    } catch (_) {
      return const Failure(
          AppFailure('Your habit summary could not be loaded.'));
    }
  }

  Future<Result<void>> addWater(double millilitres) async {
    try {
      await _api.post(ApiEndpoints.hydration, data: {
        'millilitres': millilitres,
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'clientOperationId': const Uuid().v4(),
      });
      return const Success(null);
    } catch (_) {
      return const Failure(AppFailure('Water could not be logged.'));
    }
  }

  Future<Result<void>> addFast(DateTime start, DateTime end) async {
    try {
      await _api.post(ApiEndpoints.fasting, data: {
        'startedAtUtc': start.toUtc().toIso8601String(),
        'endedAtUtc': end.toUtc().toIso8601String(),
        'clientOperationId': const Uuid().v4(),
      });
      return const Success(null);
    } catch (_) {
      return const Failure(AppFailure('Fasting window could not be saved.'));
    }
  }

  Future<Result<List<HabitReminder>>> reminders() async {
    try {
      final response = await _api.get(ApiEndpoints.reminders);
      return Success((response.data as List)
          .map((value) =>
              HabitReminder.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList());
    } catch (_) {
      return const Failure(AppFailure('Reminders could not be loaded.'));
    }
  }

  Future<Result<HabitReminder>> saveReminder({
    String? id,
    required String type,
    required String localTime,
    required String timezone,
    required bool enabled,
  }) async {
    try {
      final reminderId = id ?? const Uuid().v4();
      final response = await _api.put(ApiEndpoints.reminder(reminderId), data: {
        'type': type,
        'localTime': '$localTime:00',
        'timezone': timezone,
        'isEnabled': enabled,
        'clientOperationId': const Uuid().v4(),
      });
      return Success(HabitReminder.fromJson(
          Map<String, dynamic>.from(response.data as Map)));
    } catch (_) {
      return const Failure(AppFailure('Reminder could not be saved.'));
    }
  }
}
