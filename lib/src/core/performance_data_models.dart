import 'package:flutter/material.dart';

/// Placement options for the overlay bubble/panel.
enum PerformanceOverlayPosition { topLeft, topRight, bottomLeft, bottomRight }

/// Whether the monitor is drawing an overlay on-screen.
enum PerformanceMonitorMode { disabled, visible, hidden }

/// Simple health buckets for coloring UI.
enum PerformanceHealth { smooth, moderate, poor }

/// Aggregated metrics emitted by the monitor.
class PerformanceMetrics {
  const PerformanceMetrics({
    required this.fps,
    required this.averageBuildTimeMs,
    required this.averageRasterTimeMs,
    required this.rebuildsPerSecond,
    required this.memoryInMB,
    required this.jankPerSecond,
    required this.cpuUsagePercent,
    required this.hotReloadCount,
    required this.hotRestartCount,
    required this.timestamp,
  });

  final double fps;
  final double averageBuildTimeMs;
  final double averageRasterTimeMs;
  final int rebuildsPerSecond;
  final double? memoryInMB;
  /// Best-effort count of frames that exceeded the frame budget.
  final int jankPerSecond;
  /// Best-effort CPU utilization for the process (0-100), or null if unavailable.
  final double? cpuUsagePercent;
  final int hotReloadCount;
  final int hotRestartCount;
  final DateTime timestamp;

  PerformanceMetrics copyWith({
    double? fps,
    double? averageBuildTimeMs,
    double? averageRasterTimeMs,
    int? rebuildsPerSecond,
    double? memoryInMB,
    int? jankPerSecond,
    double? cpuUsagePercent,
    int? hotReloadCount,
    int? hotRestartCount,
    DateTime? timestamp,
  }) {
    return PerformanceMetrics(
      fps: fps ?? this.fps,
      averageBuildTimeMs: averageBuildTimeMs ?? this.averageBuildTimeMs,
      averageRasterTimeMs: averageRasterTimeMs ?? this.averageRasterTimeMs,
      rebuildsPerSecond: rebuildsPerSecond ?? this.rebuildsPerSecond,
      memoryInMB: memoryInMB ?? this.memoryInMB,
      jankPerSecond: jankPerSecond ?? this.jankPerSecond,
      cpuUsagePercent: cpuUsagePercent ?? this.cpuUsagePercent,
      hotReloadCount: hotReloadCount ?? this.hotReloadCount,
      hotRestartCount: hotRestartCount ?? this.hotRestartCount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static PerformanceMetrics empty() => PerformanceMetrics(
    fps: 0,
    averageBuildTimeMs: 0,
    averageRasterTimeMs: 0,
    rebuildsPerSecond: 0,
    memoryInMB: null,
    jankPerSecond: 0,
    cpuUsagePercent: null,
    hotReloadCount: 0,
    hotRestartCount: 0,
    timestamp: DateTime.now(),
  );
}

/// Basic theme configuration for the overlay.
class PerformanceMonitorThemeData {
  const PerformanceMonitorThemeData({
    required this.bubbleColor,
    required this.panelBackgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.borderColor,
    required this.successColor,
    required this.warningColor,
    required this.dangerColor,
  });

  final Color bubbleColor;
  final Color panelBackgroundColor;
  final Color textColor;
  final Color accentColor;
  final Color borderColor;
  final Color successColor;
  final Color warningColor;
  final Color dangerColor;

  const factory PerformanceMonitorThemeData.light() = _LightThemeData;

  const factory PerformanceMonitorThemeData.dark() = _DarkThemeData;
}

class _LightThemeData extends PerformanceMonitorThemeData {
  const _LightThemeData()
    : super(
        bubbleColor: const Color(0xE5FFFFFF),
        panelBackgroundColor: const Color(0xF2FFFFFF),
        textColor: const Color(0xDD000000),
        accentColor: Colors.teal,
        borderColor: const Color(0x1F000000),
        successColor: const Color(0xFF2E8B57),
        warningColor: const Color(0xFFD35400),
        dangerColor: const Color(0xFFD32F2F),
      );
}

class _DarkThemeData extends PerformanceMonitorThemeData {
  const _DarkThemeData()
    : super(
        bubbleColor: const Color(0xBF000000),
        panelBackgroundColor: const Color(0xED1C1C1C),
        textColor: const Color(0xB3FFFFFF),
        accentColor: Colors.lightBlueAccent,
        borderColor: const Color(0x1AFFFFFF),
        successColor: const Color(0xFF6FCF97),
        warningColor: const Color(0xFFF2994A),
        dangerColor: const Color(0xFFFF6B6B),
      );
}
