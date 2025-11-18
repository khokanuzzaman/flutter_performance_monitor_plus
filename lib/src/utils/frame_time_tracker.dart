import 'package:flutter/scheduler.dart';

class FrameTimeTracker {
  FrameTimeTracker({this.sampleSize = 120});

  final int sampleSize;
  final List<int> _buildMicros = <int>[];
  final List<int> _rasterMicros = <int>[];

  void addTimings(FrameTiming timing) {
    _buildMicros.add(timing.buildDuration.inMicroseconds);
    _rasterMicros.add(timing.rasterDuration.inMicroseconds);
    if (_buildMicros.length > sampleSize) _buildMicros.removeAt(0);
    if (_rasterMicros.length > sampleSize) _rasterMicros.removeAt(0);
  }

  double get averageBuildMs => _buildMicros.isEmpty
      ? 0
      : _buildMicros.reduce((a, b) => a + b) / _buildMicros.length / 1000;

  double get averageRasterMs => _rasterMicros.isEmpty
      ? 0
      : _rasterMicros.reduce((a, b) => a + b) / _rasterMicros.length / 1000;

  void reset() {
    _buildMicros.clear();
    _rasterMicros.clear();
  }
}
