import 'package:flutter/material.dart';

import '../core/performance_data_models.dart';
import '../core/performance_monitor_config.dart';
import '../core/performance_monitor_controller.dart';
import '../network/network_log_entry.dart';
import 'performance_monitor_bubble.dart';
import 'performance_monitor_panel.dart';
import 'package:url_launcher/url_launcher.dart';

class PerformanceMonitorScope extends InheritedWidget {
  const PerformanceMonitorScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final PerformanceMonitorController controller;

  static PerformanceMonitorController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PerformanceMonitorScope>()
      ?.controller;

  @override
  bool updateShouldNotify(covariant PerformanceMonitorScope oldWidget) =>
      oldWidget.controller != controller;
}

class PerformanceMonitorOverlay extends StatefulWidget {
  PerformanceMonitorOverlay({
    super.key,
    required this.child,
    this.config = const PerformanceMonitorConfig(),
    this.controller,
    PerformanceMonitorMode? mode,
  }) : mode = mode ?? config.mode;

  final Widget child;
  final PerformanceMonitorConfig config;
  final PerformanceMonitorController? controller;
  final PerformanceMonitorMode mode;

  @override
  State<PerformanceMonitorOverlay> createState() =>
      _PerformanceMonitorOverlayState();
}

class _PerformanceMonitorOverlayState extends State<PerformanceMonitorOverlay> {
  late final PerformanceMonitorController _controller;
  Offset? _offset;
  bool _ownsController = false;
  _PeekSide? _peekSide;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        PerformanceMonitorController(config: widget.config);
    _ownsController = widget.controller == null;
    _controller.markAsPrimary();
    _controller.setMode(widget.mode);
    _controller.start();
  }

  @override
  void reassemble() {
    super.reassemble();
    _controller.recordHotReload();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateOffset(Offset delta, Size maxSize, double overlayWidth) {
    _peekSide = null;
    final next = (_offset ?? _initialOffset(maxSize)) + delta;
    final clamped = Offset(
      next.dx.clamp(
        -24.0,
        (maxSize.width - overlayWidth + 16).clamp(8.0, maxSize.width),
      ),
      next.dy.clamp(8.0, (maxSize.height - 80).clamp(8.0, maxSize.height)),
    );
    setState(() => _offset = clamped);
  }

  void _ensureInitialPosition(Size size) {
    if (_offset != null) return;
    _peekSide ??= _defaultPeekSide();
    _offset = _peekSide != null
        ? _initialPeekOffset(size, _peekSide!)
        : _initialOffset(size);
  }

  _PeekSide _defaultPeekSide() {
    switch (widget.config.overlayPosition) {
      case PerformanceOverlayPosition.topLeft:
      case PerformanceOverlayPosition.bottomLeft:
        return _PeekSide.left;
      case PerformanceOverlayPosition.topRight:
      case PerformanceOverlayPosition.bottomRight:
        return _PeekSide.right;
    }
  }

  void _snapToEdge(Size size) {
    final current = _offset ?? _initialOffset(size);
    final side =
        current.dx < size.width / 2 ? _PeekSide.left : _PeekSide.right;
    final y = current.dy.clamp(8.0, (size.height - 80).clamp(8.0, size.height));
    final x = side == _PeekSide.left ? -12.0 : size.width - 20.0;
    setState(() {
      _peekSide = side;
      _offset = Offset(x, y);
    });
  }

  void _togglePeek(Size size) {
    if (_peekSide != null) {
      final base = _offset ?? _initialOffset(size);
      final clamped = Offset(
        base.dx.clamp(8.0, (size.width - 160).clamp(8.0, size.width)),
        base.dy.clamp(8.0, (size.height - 80).clamp(8.0, size.height)),
      );
      setState(() {
        _peekSide = null;
        _offset = clamped;
      });
      return;
    }
    _snapToEdge(size);
  }

  Offset _initialOffset(Size size) {
    const margin = 12.0;
    switch (widget.config.overlayPosition) {
      case PerformanceOverlayPosition.topLeft:
        return const Offset(margin, margin + 32);
      case PerformanceOverlayPosition.topRight:
        return Offset(size.width - 200 - margin, margin + 32);
      case PerformanceOverlayPosition.bottomLeft:
        return Offset(margin, size.height - 160);
      case PerformanceOverlayPosition.bottomRight:
        return Offset(size.width - 200 - margin, size.height - 160);
    }
  }

  Offset _initialPeekOffset(Size size, _PeekSide side) {
    final base = _initialOffset(size);
    final y =
        base.dy.clamp(8.0, (size.height - 80).clamp(8.0, size.height)).toDouble();
    final x = side == _PeekSide.left ? -12.0 : size.width - 20.0;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final textDirection =
        Directionality.maybeOf(context) ?? TextDirection.ltr;
    return Directionality(
      textDirection: textDirection,
      child: PerformanceMonitorScope(
        controller: _controller,
        child: ValueListenableBuilder<PerformanceMonitorMode>(
          valueListenable: _controller.mode,
          builder: (context, mode, _) {
            if (mode == PerformanceMonitorMode.disabled) {
              return widget.child;
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                _ensureInitialPosition(size);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.child,
                    if (mode == PerformanceMonitorMode.visible)
                      _buildOverlay(size),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverlay(Size availableSize) {
    return ValueListenableBuilder<PerformanceMetrics>(
      valueListenable: _controller.metrics,
      builder: (context, metrics, _) {
        final theme = widget.config.theme;
        final opacity = widget.config.overlayOpacity.clamp(0.0, 1.0);
        final health = _healthFromMetrics(metrics);
        return Positioned(
          left: _offset?.dx,
          top: _offset?.dy,
          child: ValueListenableBuilder<bool>(
            valueListenable: _controller.isExpanded,
            builder: (context, expanded, __) {
              final overlayWidth = expanded ? 320.0 : (_peekSide != null ? 28.0 : 160.0);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) {
                  _peekSide = null;
                  _offset ??= _initialOffset(availableSize);
                },
                onPanUpdate: (details) =>
                    _updateOffset(details.delta, availableSize, overlayWidth),
                onPanEnd: (_) {
                  if (!expanded) _snapToEdge(availableSize);
                },
                child: Opacity(
                  opacity: opacity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: expanded
                            ? _ExpandedOverlay(
                                key: const ValueKey('expanded'),
                                controller: _controller,
                                metrics: metrics,
                                theme: theme,
                                width: 320,
                              )
                            : (_peekSide != null
                                ? _PeekHandle(
                                    key: const ValueKey('peek'),
                                    theme: theme,
                                    side: _peekSide!,
                                    onTap: () => _togglePeek(availableSize),
                                    onLongPress: () => _openDocs(context),
                                  )
                                : PerformanceMonitorBubble(
                                    key: const ValueKey('collapsed'),
                                    metrics: metrics,
                                    theme: theme,
                                    health: health,
                                    onTap: () {
                                      setState(() => _peekSide = null);
                                      _controller.toggleExpanded();
                                    },
                                    onLongPress: () => _openDocs(context),
                                    onDoubleTap: () => _togglePeek(availableSize),
                                  )),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

enum _PeekSide { left, right }

PerformanceHealth _healthFromMetrics(PerformanceMetrics metrics) {
  if (metrics.jankPerSecond > 3 || metrics.fps < 40) {
    return PerformanceHealth.poor;
  }
  if (metrics.jankPerSecond > 1 || metrics.fps < 55) {
    return PerformanceHealth.moderate;
  }
  return PerformanceHealth.smooth;
}

class _ExpandedOverlay extends StatelessWidget {
  const _ExpandedOverlay({
    super.key,
    required this.controller,
    required this.metrics,
    required this.theme,
    required this.width,
  });

  final PerformanceMonitorController controller;
  final PerformanceMetrics metrics;
  final PerformanceMonitorThemeData theme;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<NetworkLogEntry>>(
      valueListenable: controller.networkLogs,
      builder: (context, logs, _) => PerformanceMonitorPanel(
        metrics: metrics,
        networkLogs: logs,
        theme: theme,
        width: width,
        onCollapse: controller.toggleExpanded,
        onOpenDocs: () => _openDocs(context),
      ),
    );
  }
}

class _PeekHandle extends StatelessWidget {
  const _PeekHandle({
    super.key,
    required this.theme,
    required this.side,
    required this.onTap,
    required this.onLongPress,
  });

  final PerformanceMonitorThemeData theme;
  final _PeekSide side;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.horizontal(
      left: side == _PeekSide.right ? const Radius.circular(12) : Radius.zero,
      right: side == _PeekSide.left ? const Radius.circular(12) : Radius.zero,
    );
    return Material(
      color: theme.bubbleColor.withOpacity(0.8),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: 28,
          height: 72,
          child: Icon(
            side == _PeekSide.left
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }
}

Future<void> _openDocs(BuildContext context) async {
  final uri = Uri.parse('https://docs.flutter.dev/perf/metrics');
  bool launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    launched = false;
  }
  if (launched) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    const SnackBar(
      content: Text('Could not open Flutter performance metrics guide'),
    ),
  );
}
