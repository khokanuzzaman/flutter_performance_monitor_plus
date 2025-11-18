import 'package:flutter/material.dart';

import '../core/performance_data_models.dart';

class PerformanceMonitorBubble extends StatelessWidget {
  const PerformanceMonitorBubble({
    super.key,
    required this.metrics,
    required this.theme,
    required this.health,
    required this.onTap,
    this.onLongPress,
    this.onDoubleTap,
  });

  final PerformanceMetrics metrics;
  final PerformanceMonitorThemeData theme;
  final PerformanceHealth health;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final severityColor = _healthColor(health, theme);
    return Material(
      color: theme.bubbleColor,
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: severityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _metric('FPS', metrics.fps.toStringAsFixed(0),
                      color: severityColor),
                ],
              ),
              const SizedBox(height: 6),
              _metric(
                'Build',
                '${metrics.averageBuildTimeMs.toStringAsFixed(1)} ms',
              ),
              const SizedBox(height: 6),
              _metric(
                'Mem',
                metrics.memoryInMB != null
                    ? '${metrics.memoryInMB!.toStringAsFixed(1)} MB'
                    : 'n/a',
              ),
              const SizedBox(height: 6),
              _metric(
                'Jank',
                '${metrics.jankPerSecond}/s',
                color: severityColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.textColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(color: color ?? theme.textColor, fontSize: 12),
        ),
      ],
    );
  }
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
