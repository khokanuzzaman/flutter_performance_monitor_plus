import 'performance_data_models.dart';

class PerformanceMonitorConfig {
  const PerformanceMonitorConfig({
    this.enableFps = true,
    this.enableFrameTime = true,
    this.enableRebuildsCount = true,
    this.enableMemory = true,
    this.enableCpuUsage = true,
    this.enableNetworkLogging = true,
    this.enableHotReloadStats = true,
    this.overlayPosition = PerformanceOverlayPosition.topRight,
    this.overlayOpacity = 0.95,
    this.expandedByDefault = false,
    this.metricsRefreshRate = const Duration(milliseconds: 500),
    this.maxNetworkEntries = 50,
    PerformanceMonitorThemeData? theme,
    this.mode = PerformanceMonitorMode.visible,
  }) : theme = theme ?? const PerformanceMonitorThemeData.dark();

  final bool enableFps;
  final bool enableFrameTime;
  final bool enableRebuildsCount;
  final bool enableMemory;
  final bool enableCpuUsage;
  final bool enableNetworkLogging;
  final bool enableHotReloadStats;
  final PerformanceOverlayPosition overlayPosition;
  final double overlayOpacity;
  final bool expandedByDefault;
  final PerformanceMonitorThemeData theme;
  final Duration metricsRefreshRate;
  final int maxNetworkEntries;
  final PerformanceMonitorMode mode;

  PerformanceMonitorConfig copyWith({
    bool? enableFps,
    bool? enableFrameTime,
    bool? enableRebuildsCount,
    bool? enableMemory,
    bool? enableCpuUsage,
    bool? enableNetworkLogging,
    bool? enableHotReloadStats,
    PerformanceOverlayPosition? overlayPosition,
    double? overlayOpacity,
    bool? expandedByDefault,
    PerformanceMonitorThemeData? theme,
    Duration? metricsRefreshRate,
    int? maxNetworkEntries,
    PerformanceMonitorMode? mode,
  }) {
    return PerformanceMonitorConfig(
      enableFps: enableFps ?? this.enableFps,
      enableFrameTime: enableFrameTime ?? this.enableFrameTime,
      enableRebuildsCount: enableRebuildsCount ?? this.enableRebuildsCount,
      enableMemory: enableMemory ?? this.enableMemory,
      enableCpuUsage: enableCpuUsage ?? this.enableCpuUsage,
      enableNetworkLogging: enableNetworkLogging ?? this.enableNetworkLogging,
      enableHotReloadStats: enableHotReloadStats ?? this.enableHotReloadStats,
      overlayPosition: overlayPosition ?? this.overlayPosition,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      expandedByDefault: expandedByDefault ?? this.expandedByDefault,
      theme: theme ?? this.theme,
      metricsRefreshRate: metricsRefreshRate ?? this.metricsRefreshRate,
      maxNetworkEntries: maxNetworkEntries ?? this.maxNetworkEntries,
      mode: mode ?? this.mode,
    );
  }
}
