import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/core/time/clock_service.dart';
import 'package:nutrition_tracker_app/features/fasting/data/fasting_repository.dart';

class FakeClock implements ClockService {
  FakeClock(this.value);
  DateTime value;
  @override
  DateTime nowUtc() => value;
}

void main() {
  test('fast progress is derived from UTC timestamps without timer drift', () {
    final clock = FakeClock(DateTime.utc(2026, 7, 13, 12));
    final fast = ActiveFast(
        id: 'fast',
        status: FastingStatus.active,
        startedAtUtc: DateTime.utc(2026, 7, 13, 10),
        targetMinutes: 180,
        plannedEndAtUtc: DateTime.utc(2026, 7, 13, 13),
        version: 1);
    expect(fast.elapsed(clock), const Duration(hours: 2));
    expect(fast.remaining(clock), const Duration(hours: 1));
    clock.value = DateTime.utc(2026, 7, 13, 14);
    expect(fast.reached(clock), isTrue);
    expect(fast.remaining(clock), Duration.zero);
  });
}
