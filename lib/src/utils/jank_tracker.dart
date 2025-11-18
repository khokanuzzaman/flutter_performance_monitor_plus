import 'dart:collection';

import 'dart:ui';

/// Tracks frames that exceed the frame budget (best-effort jank detector).
class JankTracker {
  JankTracker({
    this.window = const Duration(seconds: 1),
    this.budget = const Duration(milliseconds: 16),
  });

  final Duration window;
  final Duration budget;

  final Queue<int> _jankFrameEnds = Queue<int>();

  void addTimings(FrameTiming timing) {
    final total = timing.buildDuration + timing.rasterDuration;
    if (total > budget) {
      final endMicros = timing.timestampInMicroseconds(FramePhase.rasterFinish);
      _jankFrameEnds.add(endMicros);
      final threshold = endMicros - window.inMicroseconds;
      while (_jankFrameEnds.isNotEmpty && _jankFrameEnds.first < threshold) {
        _jankFrameEnds.removeFirst();
      }
    }
  }

  int get jankPerWindow => _jankFrameEnds.length;

  void reset() {
    _jankFrameEnds.clear();
  }
}
