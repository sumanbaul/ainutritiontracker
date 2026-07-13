import 'dart:async';

enum SyncState { synced, offline, synchronizing, pending, failed, conflict }

class SyncStatus {
  const SyncStatus(this.state, {this.pendingOperations = 0, this.message});
  final SyncState state;
  final int pendingOperations;
  final String? message;
  bool get isOffline => state == SyncState.offline;
}

class SyncStatusController {
  final _controller = StreamController<SyncStatus>.broadcast();
  SyncStatus _current = const SyncStatus(SyncState.synced);
  SyncStatus get current => _current;
  Stream<SyncStatus> get stream => _controller.stream;
  void publish(SyncStatus value) {
    _current = value;
    _controller.add(value);
  }

  Future<void> dispose() => _controller.close();
}
