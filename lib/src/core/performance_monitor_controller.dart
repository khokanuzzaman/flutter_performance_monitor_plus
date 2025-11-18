import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/network_log_entry.dart';
import 'performance_collector.dart';
import 'performance_data_models.dart';
import 'performance_monitor_config.dart';

class PerformanceMonitorController extends ChangeNotifier {
  PerformanceMonitorController({this.config = const PerformanceMonitorConfig()})
    : networkLogs = ValueNotifier<List<NetworkLogEntry>>(<NetworkLogEntry>[]),
      mode = ValueNotifier<PerformanceMonitorMode>(config.mode),
      isExpanded = ValueNotifier<bool>(config.expandedByDefault),
      isVisible = ValueNotifier<bool>(
        config.mode == PerformanceMonitorMode.visible,
      ) {
    _collector = PerformanceCollector(config: config);
    metrics = ValueNotifier<PerformanceMetrics>(_collector.metrics.value);
    _metricsController = StreamController<PerformanceMetrics>.broadcast();
    _collector.metrics.addListener(_handleCollectorMetrics);
    _handleCollectorMetrics();
  }

  final PerformanceMonitorConfig config;
  late final PerformanceCollector _collector;

  late final ValueNotifier<PerformanceMetrics> metrics;
  final ValueNotifier<List<NetworkLogEntry>> networkLogs;
  final ValueNotifier<PerformanceMonitorMode> mode;
  final ValueNotifier<bool> isExpanded;
  final ValueNotifier<bool> isVisible;
  final ValueNotifier<int> hotReloadCount = ValueNotifier<int>(0);
  final ValueNotifier<int> hotRestartCount = ValueNotifier<int>(0);
  late final StreamController<PerformanceMetrics> _metricsController;

  bool _started = false;

  static PerformanceMonitorController? _primary;
  static PerformanceMonitorController? get primary => _primary;

  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;

  void markAsPrimary() {
    _primary = this;
  }

  void _handleCollectorMetrics() {
    final base = _collector.metrics.value;
    final merged = base.copyWith(
      hotReloadCount: hotReloadCount.value,
      hotRestartCount: hotRestartCount.value,
    );
    metrics.value = merged;
    _metricsController.add(merged);
  }

  void start() {
    if (_started || mode.value == PerformanceMonitorMode.disabled) return;
    _collector.start();
    _started = true;
  }

  void stop() {
    if (!_started) return;
    _collector.stop();
    _started = false;
  }

  void setMode(PerformanceMonitorMode newMode) {
    if (mode.value == newMode) return;
    mode.value = newMode;
    isVisible.value = newMode == PerformanceMonitorMode.visible;
    if (newMode == PerformanceMonitorMode.disabled) {
      stop();
    } else {
      start();
    }
    notifyListeners();
  }

  void toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }

  void recordHotReload() {
    if (!config.enableHotReloadStats) return;
    hotReloadCount.value++;
    metrics.value = metrics.value.copyWith(
      hotReloadCount: hotReloadCount.value,
    );
    _metricsController.add(metrics.value);
    notifyListeners();
  }

  void recordHotRestart() {
    if (!config.enableHotReloadStats) return;
    hotRestartCount.value++;
    metrics.value = metrics.value.copyWith(
      hotRestartCount: hotRestartCount.value,
    );
    _metricsController.add(metrics.value);
    notifyListeners();
  }

  void logNetworkRequest({
    required String method,
    required String url,
    required Duration duration,
    int? statusCode,
    Object? error,
  }) {
    if (!config.enableNetworkLogging) return;
    final uri = Uri.tryParse(url) ?? Uri(path: url);
    final updated = List<NetworkLogEntry>.from(networkLogs.value)
      ..add(
        NetworkLogEntry(
          method: method.toUpperCase(),
          url: uri,
          duration: duration,
          timestamp: DateTime.now(),
          statusCode: statusCode,
          error: error,
        ),
      );
    final max = config.maxNetworkEntries;
    networkLogs.value = updated.length > max
        ? updated.sublist(updated.length - max)
        : updated;
    notifyListeners();
  }

  @override
  void dispose() {
    _collector.metrics.removeListener(_handleCollectorMetrics);
    _collector.dispose();
    networkLogs.dispose();
    mode.dispose();
    isExpanded.dispose();
    isVisible.dispose();
    hotReloadCount.dispose();
    hotRestartCount.dispose();
    _metricsController.close();
    if (identical(_primary, this)) {
      _primary = null;
    }
    super.dispose();
  }
}
