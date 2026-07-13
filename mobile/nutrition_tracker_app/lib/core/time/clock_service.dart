import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ClockService {
  DateTime nowUtc();
}

class SystemClock implements ClockService {
  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

final clockProvider = Provider<ClockService>((_) => SystemClock());
