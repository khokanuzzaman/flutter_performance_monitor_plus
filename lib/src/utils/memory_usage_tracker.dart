import 'dart:async';

import 'package:flutter/foundation.dart';

import 'memory/memory_platform_stub.dart'
    if (dart.library.io) 'memory/memory_platform_io.dart';

class MemoryUsageTracker {
  MemoryUsageTracker({this.interval = const Duration(seconds: 1)});

  final Duration interval;
  final ValueNotifier<double?> currentValue = ValueNotifier<double?>(null);

  Timer? _timer;

  void start() {
    _timer ??= Timer.periodic(interval, (_) {
      currentValue.value = getMemoryInMB();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    currentValue.dispose();
  }
}
