import 'dart:async';

import 'package:flutter/foundation.dart';

import 'cpu/cpu_platform_stub.dart'
    if (dart.library.io) 'cpu/cpu_platform_io.dart';

/// Best-effort CPU sampler; returns null when not supported.
class CpuUsageTracker {
  CpuUsageTracker({this.interval = const Duration(seconds: 1)});

  final Duration interval;
  final ValueNotifier<double?> currentValue = ValueNotifier<double?>(null);

  Timer? _timer;

  void start() {
    _timer ??= Timer.periodic(interval, (_) {
      currentValue.value = getCpuUsagePercent();
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
