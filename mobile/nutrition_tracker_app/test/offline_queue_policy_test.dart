import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/core/sync/offline_sync_service.dart';

void main() {
  test('offline replay is user scoped and exponential backoff is bounded', () {
    expect(OfflineSyncService.belongsToUser('user-a', 'user-a'), isTrue);
    expect(OfflineSyncService.belongsToUser('user-a', 'user-b'), isFalse);
    expect(OfflineSyncService.retryDelay(1), const Duration(seconds: 10));
    expect(OfflineSyncService.retryDelay(20), const Duration(seconds: 300));
  });
}
