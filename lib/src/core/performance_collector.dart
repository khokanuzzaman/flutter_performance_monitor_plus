import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../utils/fps_tracker.dart';
import '../utils/frame_time_tracker.dart';
import '../utils/jank_tracker.dart';
import '../utils/memory_usage_tracker.dart';
import '../utils/cpu_usage_tracker.dart';
import '../utils/rebuild_tracker.dart';
import 'performance_data_models.dart';
import 'performance_monitor_config.dart';

class PerformanceCollector {
  PerformanceCollector({required this.config})
    : metrics = ValueNotifier<PerformanceMetrics>(PerformanceMetrics.empty());

  final PerformanceMonitorConfig config;
  final FpsTracker _fpsTracker = FpsTracker();
  final FrameTimeTracker _frameTimeTracker = FrameTimeTracker();
  final RebuildTracker _rebuildTracker = RebuildTracker();
  final MemoryUsageTracker _memoryUsageTracker = MemoryUsageTracker();
  final CpuUsageTracker _cpuUsageTracker = CpuUsageTracker();
  final JankTracker _jankTracker = JankTracker();
  final ValueNotifier<PerformanceMetrics> metrics;

  Timer? _emitTimer;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    SchedulerBinding.instance.addTimingsCallback(_handleFrameTimings);
    if (config.enableRebuildsCount) {
      _rebuildTracker.start();
    }
    if (config.enableMemory) {
      _memoryUsageTracker.start();
    }
    if (config.enableCpuUsage) {
      _cpuUsageTracker.start();
    }
    _emitTimer = Timer.periodic(
      config.metricsRefreshRate,
      (_) => _emitMetrics(),
    );
  }

  void _handleFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      if (config.enableFps) {
        _fpsTracker.addTimings(timing);
      }
      if (config.enableFrameTime) {
        _frameTimeTracker.addTimings(timing);
      }
      if (config.enableFrameTime) {
        _jankTracker.addTimings(timing);
      }
    }
  }

  void _emitMetrics() {
    metrics.value = PerformanceMetrics(
      fps: config.enableFps ? _fpsTracker.fps : 0,
      averageBuildTimeMs: config.enableFrameTime
          ? _frameTimeTracker.averageBuildMs
          : 0,
      averageRasterTimeMs: config.enableFrameTime
          ? _frameTimeTracker.averageRasterMs
          : 0,
      rebuildsPerSecond: config.enableRebuildsCount
          ? _rebuildTracker.rebuildsPerWindow.value
          : 0,
      memoryInMB: config.enableMemory
          ? _memoryUsageTracker.currentValue.value
          : null,
      jankPerSecond: config.enableFrameTime ? _jankTracker.jankPerWindow : 0,
      cpuUsagePercent: config.enableCpuUsage
          ? _cpuUsageTracker.currentValue.value
          : null,
      hotReloadCount: metrics.value.hotReloadCount,
      hotRestartCount: metrics.value.hotRestartCount,
      timestamp: DateTime.now(),
    );
  }

  void stop() {
    if (!_running) return;
    _running = false;
    SchedulerBinding.instance.removeTimingsCallback(_handleFrameTimings);
    _emitTimer?.cancel();
    _emitTimer = null;
    _fpsTracker.reset();
    _frameTimeTracker.reset();
    _rebuildTracker.stop();
    _memoryUsageTracker.stop();
    _cpuUsageTracker.stop();
    _jankTracker.reset();
  }

  void dispose() {
    stop();
    _rebuildTracker.dispose();
    _memoryUsageTracker.dispose();
    _cpuUsageTracker.dispose();
    metrics.dispose();
  }
}
