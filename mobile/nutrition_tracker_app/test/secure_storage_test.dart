import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/core/storage/secure_storage_service.dart';

void main() {
  test('in-memory secure storage writes reads and clears values', () async {
    final storage = InMemorySecureStorageService();
    await storage.write('key', 'value');
    expect(await storage.read('key'), 'value');
    await storage.delete('key');
    expect(await storage.read('key'), isNull);
  });
}
