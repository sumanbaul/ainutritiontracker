import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../networking/api_client.dart';
import '../storage/local_database.dart';
import '../../features/auth/data/auth_service.dart';
import 'sync_status.dart';

class OfflineSyncService {
  OfflineSyncService(this._db, this._api, this._status);
  final LocalDatabase _db;
  final ApiClient _api;
  final SyncStatusController _status;
  static Duration retryDelay(int retryCount) =>
      Duration(seconds: min(300, pow(2, retryCount).toInt() * 5));
  static bool belongsToUser(String queuedUserId, String currentUserId) =>
      queuedUserId == currentUserId;
  Future<String> enqueue(
      {required String userId,
      required String operation,
      required String entityType,
      required String entityId,
      required Map<String, dynamic> payload,
      String? dependencyGroup}) async {
    final id = const Uuid().v4();
    await _db.enqueueSync(
        id: id,
        operationType: operation,
        entityType: entityType,
        entityId: entityId,
        userId: userId,
        payloadJson: jsonEncode(payload),
        idempotencyKey: id,
        dependencyGroup: dependencyGroup);
    return id;
  }

  Future<void> replay(String userId) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.every((value) => value == ConnectivityResult.none)) {
      _status.publish(const SyncStatus(SyncState.offline));
      return;
    }
    await _db.recoverInterrupted(userId);
    final queue = await _db.pendingSync(userId);
    if (queue.isEmpty) {
      _status.publish(const SyncStatus(SyncState.synced));
      return;
    }
    _status.publish(
        SyncStatus(SyncState.synchronizing, pendingOperations: queue.length));
    for (final item in queue) {
      if (item.nextRetryAt?.isAfter(DateTime.now().toUtc()) == true) continue;
      await _db.updateSyncStatus(item.id, 'Processing');
      try {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final path = payload.remove('_path') as String;
        final method = payload.remove('_method') as String? ?? 'POST';
        if (method == 'PUT') {
          await _api.put(path, data: payload);
        } else {
          await _api.post(path, data: payload);
        }
        await _db.updateSyncStatus(item.id, 'Succeeded');
      } on DioException catch (error) {
        if (error.response?.statusCode == 409) {
          await _db.updateSyncStatus(item.id, 'Conflict',
              error: 'Server data changed. Review before retrying.');
          _status.publish(const SyncStatus(SyncState.conflict,
              message: 'Review a conflicting change.'));
          continue;
        }
        final retries = item.retryCount + 1;
        if (retries >= 5) {
          await _db.updateSyncStatus(item.id, 'Failed',
              error: 'Retry limit reached.', retryCount: retries);
          continue;
        }
        final delay = retryDelay(retries);
        await _db.updateSyncStatus(item.id, 'Failed',
            error: 'Waiting to retry.',
            nextRetryAt: DateTime.now().toUtc().add(delay),
            retryCount: retries);
        break; // preserve FIFO for dependent operations
      }
    }
    _status.publish(const SyncStatus(SyncState.synced));
  }
}

final syncStatusControllerProvider = Provider((ref) {
  final controller = SyncStatusController();
  ref.onDispose(controller.dispose);
  return controller;
});
final syncStatusProvider = StreamProvider<SyncStatus>(
    (ref) => ref.watch(syncStatusControllerProvider).stream);
final offlineSyncProvider = Provider((ref) => OfflineSyncService(
    ref.watch(localDatabaseProvider),
    ref.watch(apiClientProvider),
    ref.watch(syncStatusControllerProvider)));

Future<String?> currentUserScope(Ref ref) async =>
    await ref.read(developmentIdentityProvider).currentUserId() ??
    await ref.read(authServiceProvider).userId();

final offlineReplayProvider = StreamProvider<void>((ref) async* {
  Future<void> replay() async {
    final user = await currentUserScope(ref);
    if (user != null) await ref.read(offlineSyncProvider).replay(user);
  }

  await replay();
  await for (final _ in Connectivity().onConnectivityChanged) {
    await replay();
    yield null;
  }
});
