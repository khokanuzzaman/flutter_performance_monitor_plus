import 'package:flutter/material.dart';

import '../core/performance_data_models.dart';
import '../network/network_log_entry.dart';

class PerformanceMonitorPanel extends StatelessWidget {
  const PerformanceMonitorPanel({
    super.key,
    required this.metrics,
    required this.networkLogs,
    required this.theme,
    required this.onCollapse,
    required this.onOpenDocs,
    this.width = 320,
  });

  final PerformanceMetrics metrics;
  final List<NetworkLogEntry> networkLogs;
  final PerformanceMonitorThemeData theme;
  final VoidCallback onCollapse;
  final VoidCallback onOpenDocs;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.panelBackgroundColor,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Performance',
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onOpenDocs,
                    icon:
                        Icon(Icons.help_outline, size: 18, color: theme.textColor),
                  ),
                  IconButton(
                    onPressed: onCollapse,
                    icon: Icon(Icons.close, size: 18, color: theme.textColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metricTile(
                    'FPS',
                    metrics.fps.toStringAsFixed(1),
                    color: _healthColor(_healthFromMetrics(metrics), theme),
                  ),
                  _metricTile(
                    'Build',
                    '${metrics.averageBuildTimeMs.toStringAsFixed(1)} ms',
                    color:
                        _timeSeverityColor(metrics.averageBuildTimeMs, theme),
                  ),
                  _metricTile(
                    'Raster',
                    '${metrics.averageRasterTimeMs.toStringAsFixed(1)} ms',
                    color:
                        _timeSeverityColor(metrics.averageRasterTimeMs, theme),
                  ),
                  _metricTile('Rebuilds', '${metrics.rebuildsPerSecond}/s'),
                  _metricTile(
                    'Jank',
                    '${metrics.jankPerSecond}/s',
                    color: _healthColor(_healthFromMetrics(metrics), theme),
                  ),
                  _metricTile(
                    'Memory',
                    metrics.memoryInMB != null
                        ? '${metrics.memoryInMB!.toStringAsFixed(1)} MB'
                        : 'n/a',
                  ),
                  _metricTile(
                    'CPU',
                    metrics.cpuUsagePercent != null
                        ? '${metrics.cpuUsagePercent!.toStringAsFixed(1)}%'
                        : 'n/a',
                    color: _cpuColor(metrics.cpuUsagePercent, theme),
                  ),
                  _metricTile(
                    'Hot Reloads',
                    metrics.hotReloadCount.toString(),
                  ),
                  _metricTile(
                    'Hot Restarts',
                    metrics.hotRestartCount.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Network',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: networkLogs.isEmpty
                      ? Center(
                          child: Text(
                            'No requests yet',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.7),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: networkLogs.length,
                          itemBuilder: (context, index) {
                            final log =
                                networkLogs[networkLogs.length - 1 - index];
                            return _NetworkRow(log: log, theme: theme);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.bubbleColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? theme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkRow extends StatelessWidget {
  const _NetworkRow({required this.log, required this.theme});

  final NetworkLogEntry log;
  final PerformanceMonitorThemeData theme;

  String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = log.isError ? theme.warningColor : theme.successColor;
    final timeString = _formatTime(log.timestamp);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              log.method,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.url.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.textColor),
                ),
                Text(
                  '$timeString • ${log.duration.inMilliseconds} ms',
                  style: TextStyle(
                    color: theme.textColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            log.statusCode?.toString() ?? '--',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

PerformanceHealth _healthFromMetrics(PerformanceMetrics metrics) {
  if (metrics.jankPerSecond > 3 || metrics.fps < 40) {
    return PerformanceHealth.poor;
  }
  if (metrics.jankPerSecond > 1 || metrics.fps < 55) {
    return PerformanceHealth.moderate;
  }
  return PerformanceHealth.smooth;
}

Color _healthColor(PerformanceHealth health, PerformanceMonitorThemeData theme) {
  switch (health) {
    case PerformanceHealth.smooth:
      return theme.successColor;
    case PerformanceHealth.moderate:
      return theme.warningColor;
    case PerformanceHealth.poor:
      return theme.dangerColor;
  }
}

Color? _timeSeverityColor(double timeMs, PerformanceMonitorThemeData theme) {
  if (timeMs >= 24) return theme.dangerColor;
  if (timeMs >= 16) return theme.warningColor;
  return null;
}

Color? _cpuColor(double? cpuPercent, PerformanceMonitorThemeData theme) {
  if (cpuPercent == null) return null;
  if (cpuPercent >= 90) return theme.dangerColor;
  if (cpuPercent >= 65) return theme.warningColor;
  return null;
}
