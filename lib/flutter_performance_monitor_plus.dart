library flutter_performance_monitor_plus;

import 'package:flutter/material.dart';

import 'src/core/performance_data_models.dart';
import 'src/core/performance_monitor_config.dart';
import 'src/core/performance_monitor_controller.dart';
import 'src/network/monitored_http_client.dart';
import 'src/widgets/performance_monitor_overlay.dart';

export 'src/core/performance_data_models.dart';
export 'src/core/performance_monitor_config.dart';
export 'src/core/performance_monitor_controller.dart';
export 'src/network/monitored_http_client.dart';
export 'src/network/network_log_entry.dart';
export 'src/widgets/performance_monitor_overlay.dart';

/// A thin convenience widget to attach the overlay to your app root.
class PerformanceMonitorPlus extends StatelessWidget {
  const PerformanceMonitorPlus({
    super.key,
    required this.child,
    this.config = const PerformanceMonitorConfig(),
    this.mode = PerformanceMonitorMode.visible,
  });

  final Widget child;
  final PerformanceMonitorConfig config;
  final PerformanceMonitorMode mode;

  @override
  Widget build(BuildContext context) {
    return PerformanceMonitorOverlay(config: config, mode: mode, child: child);
  }

  /// Attach the overlay to an existing overlay stack.
  static PerformanceMonitorHandle attach(
    BuildContext context, {
    PerformanceMonitorConfig config = const PerformanceMonitorConfig(),
    PerformanceMonitorMode mode = PerformanceMonitorMode.visible,
  }) {
    final overlayState = Overlay.of(context, rootOverlay: true);
    if (overlayState == null) {
      throw StateError('No Overlay found in the given context.');
    }
    final controller = PerformanceMonitorController(config: config);
    controller.markAsPrimary();
    controller.setMode(mode);
    controller.start();
    final entry = OverlayEntry(
      builder: (ctx) => PerformanceMonitorOverlay(
        config: config,
        controller: controller,
        mode: mode,
        child: const SizedBox.expand(),
      ),
    );
    overlayState.insert(entry);
    return PerformanceMonitorHandle._(entry, controller);
  }

  /// Manually log network requests made outside the bundled HTTP client.
  static void logNetworkRequest({
    required String method,
    required String url,
    required Duration duration,
    int? statusCode,
    Object? error,
  }) {
    PerformanceMonitorController.primary?.logNetworkRequest(
      method: method,
      url: url,
      duration: duration,
      statusCode: statusCode,
      error: error,
    );
  }

  /// Subscribe to live metrics from the primary controller.
  static Stream<PerformanceMetrics>? get metricsStream =>
      PerformanceMonitorController.primary?.metricsStream;

  /// Increment the hot restart counter (best-effort). Call from `main` after a
  /// hot restart if you want to surface this number in the panel.
  static void recordHotRestart() {
    PerformanceMonitorController.primary?.recordHotRestart();
  }
}

/// Handle returned by [PerformanceMonitorPlus.attach] to allow deterministic teardown.
class PerformanceMonitorHandle {
  PerformanceMonitorHandle._(this.overlayEntry, this.controller);

  final OverlayEntry overlayEntry;
  final PerformanceMonitorController controller;

  void detach() {
    overlayEntry.remove();
    controller.dispose();
  }
}
