import 'dart:collection';
import 'dart:ui';

import 'package:flutter/scheduler.dart';

/// Lightweight FPS tracker using a sliding window.
class FpsTracker {
  FpsTracker({this.window = const Duration(seconds: 1)});

  final Duration window;
  final Queue<int> _frameEndTimes = Queue<int>();

  double fps = 0;

  void addTimings(FrameTiming timing) {
    final endMicros = timing.timestampInMicroseconds(FramePhase.rasterFinish);
    _frameEndTimes.add(endMicros);
    final threshold = endMicros - window.inMicroseconds;
    while (_frameEndTimes.isNotEmpty && _frameEndTimes.first < threshold) {
      _frameEndTimes.removeFirst();
    }
    fps =
        _frameEndTimes.length *
        Duration.microsecondsPerSecond /
        window.inMicroseconds.clamp(1, window.inMicroseconds);
  }

  void reset() {
    fps = 0;
    _frameEndTimes.clear();
  }
}
