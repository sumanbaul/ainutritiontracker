import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../../../core/sync/offline_sync_service.dart';
import 'package:dio/dio.dart';

final habitRepositoryProvider = Provider((ref) => HabitRepository(
    ref.watch(apiClientProvider),
    ref.watch(offlineSyncProvider),
    () => currentUserScope(ref)));

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
  HabitRepository(this._api, [this._sync, this._userScope]);
  final ApiClient _api;
  final OfflineSyncService? _sync;
  final Future<String?> Function()? _userScope;

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
    final operationId = const Uuid().v4();
    final payload = {
      'millilitres': millilitres,
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'clientOperationId': operationId,
    };
    try {
      await _api.post(ApiEndpoints.hydration, data: payload);
      return const Success(null);
    } on DioException catch (error) {
      if (error.response == null &&
          await _queue(
              operationId, 'hydration', ApiEndpoints.hydration, payload)) {
        return const Success(null);
      }
      return const Failure(AppFailure('Water could not be logged.'));
    }
  }

  Future<Result<void>> addFast(DateTime start, DateTime end) async {
    final operationId = const Uuid().v4();
    final payload = {
      'startedAtUtc': start.toUtc().toIso8601String(),
      'endedAtUtc': end.toUtc().toIso8601String(),
      'clientOperationId': operationId
    };
    try {
      await _api.post(ApiEndpoints.fasting, data: payload);
      return const Success(null);
    } on DioException catch (error) {
      if (error.response == null &&
          await _queue(operationId, 'fasting', ApiEndpoints.fasting, payload)) {
        return const Success(null);
      }
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
    final reminderId = id ?? const Uuid().v4();
    final operationId = const Uuid().v4();
    final payload = {
      'type': type,
      'localTime': '$localTime:00',
      'timezone': timezone,
      'isEnabled': enabled,
      'clientOperationId': operationId
    };
    try {
      final response =
          await _api.put(ApiEndpoints.reminder(reminderId), data: payload);
      return Success(HabitReminder.fromJson(
          Map<String, dynamic>.from(response.data as Map)));
    } on DioException catch (error) {
      final user = await _userScope?.call();
      if (error.response == null && user != null && _sync != null) {
        await _sync.enqueue(
            userId: user,
            operation: 'upsert',
            entityType: 'reminder',
            entityId: reminderId,
            payload: {
              '_path': ApiEndpoints.reminder(reminderId),
              '_method': 'PUT',
              ...payload
            });
        return Success(HabitReminder(
            id: reminderId,
            type: type,
            localTime: localTime,
            timezone: timezone,
            isEnabled: enabled));
      }
      return const Failure(AppFailure('Reminder could not be saved.'));
    }
  }

  Future<bool> _queue(String id, String entity, String path,
      Map<String, dynamic> payload) async {
    final user = await _userScope?.call();
    if (user == null || _sync == null) return false;
    await _sync.enqueue(
        userId: user,
        operation: 'create',
        entityType: entity,
        entityId: id,
        payload: {'_path': path, '_method': 'POST', ...payload});
    return true;
  }
}
