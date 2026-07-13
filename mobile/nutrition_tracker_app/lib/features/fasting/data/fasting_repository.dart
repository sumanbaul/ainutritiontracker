// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../../../core/time/clock_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/sync/offline_sync_service.dart';

enum FastingStatus { active, completed, cancelled }

class ActiveFast {
  const ActiveFast(
      {required this.id,
      required this.status,
      required this.startedAtUtc,
      required this.targetMinutes,
      required this.plannedEndAtUtc,
      required this.version,
      this.pendingEnd = false,
      this.pendingEndAtUtc});
  final String id;
  final FastingStatus status;
  final DateTime startedAtUtc, plannedEndAtUtc;
  final int targetMinutes;
  final int version;
  final bool pendingEnd;
  final DateTime? pendingEndAtUtc;
  factory ActiveFast.fromJson(Map<String, dynamic> json) => ActiveFast(
      id: json['id'] as String,
      status:
          FastingStatus.values.byName((json['status'] as String).toLowerCase()),
      startedAtUtc: DateTime.parse(json['startedAtUtc'] as String).toUtc(),
      targetMinutes: json['targetDurationMinutes'] as int,
      plannedEndAtUtc:
          DateTime.parse(json['plannedEndAtUtc'] as String).toUtc(),
      version: json['version'] as int,
      pendingEnd: json['pendingEnd'] as bool? ?? false,
      pendingEndAtUtc: json['pendingEndAtUtc'] == null
          ? null
          : DateTime.parse(json['pendingEndAtUtc'] as String).toUtc());
  Duration elapsed(ClockService clock) {
    final value = clock.nowUtc().difference(startedAtUtc);
    return value.isNegative ? Duration.zero : value;
  }

  Duration remaining(ClockService clock) {
    final value = Duration(minutes: targetMinutes) - elapsed(clock);
    return value.isNegative ? Duration.zero : value;
  }

  bool reached(ClockService clock) =>
      elapsed(clock) >= Duration(minutes: targetMinutes);
  ActiveFast copyWith({bool? pendingEnd, DateTime? pendingEndAtUtc}) =>
      ActiveFast(
          id: id,
          status: status,
          startedAtUtc: startedAtUtc,
          targetMinutes: targetMinutes,
          plannedEndAtUtc: plannedEndAtUtc,
          version: version,
          pendingEnd: pendingEnd ?? this.pendingEnd,
          pendingEndAtUtc: pendingEndAtUtc ?? this.pendingEndAtUtc);
  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.name,
        'startedAtUtc': startedAtUtc.toIso8601String(),
        'targetDurationMinutes': targetMinutes,
        'plannedEndAtUtc': plannedEndAtUtc.toIso8601String(),
        'version': version,
        'pendingEnd': pendingEnd,
        'pendingEndAtUtc': pendingEndAtUtc?.toIso8601String()
      };
}

class FastingHistoryEntry {
  const FastingHistoryEntry(
      {required this.status,
      required this.startedAtUtc,
      this.endedAtUtc,
      required this.durationMinutes});
  final String status;
  final DateTime startedAtUtc;
  final DateTime? endedAtUtc;
  final int durationMinutes;
  factory FastingHistoryEntry.fromJson(Map<String, dynamic> json) =>
      FastingHistoryEntry(
          status: json['status'] as String,
          startedAtUtc:
              DateTime.parse(json['startedAtUtc'] as String).toLocal(),
          endedAtUtc: json['endedAtUtc'] == null
              ? null
              : DateTime.parse(json['endedAtUtc'] as String).toLocal(),
          durationMinutes: json['durationMinutes'] as int);
}

final fastingRepositoryProvider =
    Provider((ref) => FastingRepository(ref.watch(apiClientProvider)));

class FastingRepository {
  FastingRepository(this._api);
  final ApiClient _api;
  Future<Result<ActiveFast?>> active() async {
    try {
      final response = await _api.get(ApiEndpoints.activeFast);
      if (response.statusCode == 204) return const Success(null);
      return Success(
          ActiveFast.fromJson(Map<String, dynamic>.from(response.data as Map)));
    } catch (_) {
      return const Failure(AppFailure('Active fast could not be loaded.'));
    }
  }

  Future<Result<List<FastingHistoryEntry>>> history() async {
    try {
      final response = await _api.get(ApiEndpoints.fastingHistory);
      return Success((response.data as List)
          .map((item) => FastingHistoryEntry.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList());
    } catch (_) {
      return const Failure(AppFailure('Fasting history could not be loaded.'));
    }
  }

  Future<Result<ActiveFast>> start(int minutes, ClockService clock) async {
    try {
      final response = await _api.post(ApiEndpoints.startFast, data: {
        'targetDurationMinutes': minutes,
        'startedAtUtc': clock.nowUtc().toIso8601String(),
        'clientIdempotencyKey': const Uuid().v4()
      });
      return Success(
          ActiveFast.fromJson(Map<String, dynamic>.from(response.data as Map)));
    } catch (_) {
      return const Failure(
          AppFailure('Starting a fast requires a connection.'));
    }
  }

  Future<Result<ActiveFast>> end(ActiveFast fast, ClockService clock) async {
    try {
      final response = await _api.post(ApiEndpoints.endFast(fast.id), data: {
        'endedAtUtc': clock.nowUtc().toIso8601String(),
        'clientIdempotencyKey': const Uuid().v4(),
        'expectedVersion': fast.version
      });
      return Success(
          ActiveFast.fromJson(Map<String, dynamic>.from(response.data as Map)));
    } on DioException catch (error) {
      if (error.response == null) return const Failure(AppFailure('offline'));
      return const Failure(AppFailure(
          'Ending the fast could not be synced. Please retry online.'));
    }
  }

  Future<Result<ActiveFast>> cancel(ActiveFast fast) async {
    try {
      final response = await _api.post(ApiEndpoints.cancelFast(fast.id),
          data: {'expectedVersion': fast.version});
      return Success(
          ActiveFast.fromJson(Map<String, dynamic>.from(response.data as Map)));
    } catch (_) {
      return const Failure(
          AppFailure('Cancelling the fast could not be completed.'));
    }
  }
}

final fastingControllerProvider =
    StateNotifierProvider<FastingController, AsyncValue<ActiveFast?>>((ref) =>
        FastingController(
            ref.watch(fastingRepositoryProvider),
            ref.watch(clockProvider),
            ref.watch(secureStorageProvider),
            () => currentUserScope(ref),
            ref.watch(offlineSyncProvider)));

class FastingController extends StateNotifier<AsyncValue<ActiveFast?>> {
  FastingController(
      this._repository, this._clock, this._storage, this._userScope, this._sync)
      : super(const AsyncLoading()) {
    load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.valueOrNull?.status == FastingStatus.active)
        state = AsyncData(state.valueOrNull);
    });
  }
  final FastingRepository _repository;
  final ClockService _clock;
  final SecureStorageService _storage;
  final Future<String?> Function() _userScope;
  final OfflineSyncService _sync;
  late final Timer _ticker;
  Future<void> load() async {
    final user = await _userScope();
    if (user != null) {
      final cached = await _storage.read(_cacheKey(user));
      if (cached != null) {
        try {
          state = AsyncData(ActiveFast.fromJson(
              Map<String, dynamic>.from(jsonDecode(cached) as Map)));
        } catch (_) {
          await _storage.delete(_cacheKey(user));
        }
      }
    }
    final result = await _repository.active();
    if (result is Success<ActiveFast?>) {
      state = AsyncData(result.value);
      await _persist(user, result.value);
    } else if (state.valueOrNull == null)
      state = AsyncError(
          (result as Failure<ActiveFast?>).failure, StackTrace.current);
  }

  Future<Result<ActiveFast>> start(int minutes) async {
    final result = await _repository.start(minutes, _clock);
    if (result is Success<ActiveFast>) {
      state = AsyncData(result.value);
      await _persist(await _userScope(), result.value);
    }
    return result;
  }

  Future<Result<ActiveFast>> end() async {
    final fast = state.valueOrNull;
    if (fast == null)
      return const Failure(AppFailure('There is no active fast.'));
    if (fast.pendingEnd) return Success(fast);
    final result = await _repository.end(fast, _clock);
    if (result is Failure<ActiveFast> && result.failure.message == 'offline') {
      final user = await _userScope();
      if (user != null) {
        final operationId = const Uuid().v4();
        final ended = _clock.nowUtc();
        await _sync.enqueue(
            userId: user,
            operation: 'end',
            entityType: 'active_fast',
            entityId: fast.id,
            payload: {
              '_path': ApiEndpoints.endFast(fast.id),
              '_method': 'POST',
              'endedAtUtc': ended.toIso8601String(),
              'clientIdempotencyKey': operationId,
              'expectedVersion': fast.version
            });
        final pending = fast.copyWith(pendingEnd: true, pendingEndAtUtc: ended);
        state = AsyncData(pending);
        await _persist(user, pending);
        return Success(pending);
      }
    }
    if (result is Success<ActiveFast>) {
      state = const AsyncData(null);
      await _persist(await _userScope(), null);
    }
    return result;
  }

  Future<Result<ActiveFast>> cancel() async {
    final fast = state.valueOrNull;
    if (fast == null)
      return const Failure(AppFailure('There is no active fast.'));
    final result = await _repository.cancel(fast);
    if (result is Success<ActiveFast>) {
      state = const AsyncData(null);
      await _persist(await _userScope(), null);
    }
    return result;
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  String _cacheKey(String user) => 'nutrilens.active_fast.$user';
  Future<void> _persist(String? user, ActiveFast? fast) async {
    if (user == null) return;
    if (fast == null) {
      await _storage.delete(_cacheKey(user));
    } else {
      await _storage.write(_cacheKey(user), jsonEncode(fast.toJson()));
    }
  }
}
