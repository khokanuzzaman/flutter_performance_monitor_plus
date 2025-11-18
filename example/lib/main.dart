import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_performance_monitor_plus/flutter_performance_monitor_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(
    PerformanceMonitorPlus(
      config: const PerformanceMonitorConfig(
        enableNetworkLogging: true,
        enableMemory: true,
        expandedByDefault: false,
      ),
      child: const DemoApp(),
    ),
  );
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Performance Monitor Plus',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6), // light gray background
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage>
    with SingleTickerProviderStateMixin {
  late final MonitoredHttpClient _client;
  late final AnimationController _controller;
  String _status = 'Idle';
  int _rebuildTicker = 0;
  Timer? _rebuildTimer;
  StreamSubscription<PerformanceMetrics>? _metricsSub;
  PerformanceMetrics? _latestMetrics;

  @override
  void initState() {
    super.initState();
    _client = MonitoredHttpClient();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _rebuildTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() => _rebuildTicker++);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metricsSub = PerformanceMonitorPlus.metricsStream?.listen((metrics) {
        setState(() => _latestMetrics = metrics);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _rebuildTimer?.cancel();
    _client.close();
    _metricsSub?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _status = 'Requesting...');
    try {
      final response = await _client.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos/1'),
      );
      setState(() => _status = 'Status ${response.statusCode}');
    } catch (e) {
      setState(() => _status = 'Error $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Performance Monitor Plus'),
        actions: [
          IconButton(
            tooltip: 'Log manual request',
            onPressed: () {
              PerformanceMonitorPlus.logNetworkRequest(
                method: 'CUSTOM',
                url: 'app://local/action',
                duration: const Duration(milliseconds: 42),
                statusCode: 200,
              );
              setState(() => _status = 'Manual log added');
            },
            icon: const Icon(Icons.bug_report),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live rebuilds: $_rebuildTicker',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.cloud_download),
              label: const Text('Trigger sample HTTP call'),
            ),
            const SizedBox(height: 8),
            Text(_status),
            const SizedBox(height: 24),
            Text(
              'Animated box (keeps the UI busy):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + _controller.value * 0.4,
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const Spacer(),
            _MetricsSnapshot(
              metrics: _latestMetrics,
              statusText: _status,
            ),
            const Text(
              'Drag the bubble to reposition. Tap it to expand the live panel.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsSnapshot extends StatelessWidget {
  const _MetricsSnapshot({required this.metrics, required this.statusText});

  final PerformanceMetrics? metrics;
  final String statusText;
  static final Uri _metricsDocs =
      Uri.parse('https://docs.flutter.dev/perf/metrics');

  String _fmtDouble(double? value, {int fractionDigits = 1}) {
    if (value == null) return 'n/a';
    return value.toStringAsFixed(fractionDigits);
  }

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Card(
      color: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Example outputs (developer API stream):',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Open perf metrics guide',
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => _openDocs(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (m == null)
              const Text('Waiting for metrics stream...')
            else
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _chip('FPS', _fmtDouble(m.fps)),
                  _chip('Build ms', _fmtDouble(m.averageBuildTimeMs)),
                  _chip('Raster ms', _fmtDouble(m.averageRasterTimeMs)),
                  _chip('Rebuilds/s', '${m.rebuildsPerSecond}'),
                  _chip('Jank/s', '${m.jankPerSecond}'),
                  _chip('Memory MB', _fmtDouble(m.memoryInMB)),
                  _chip('CPU %', _fmtDouble(m.cpuUsagePercent)),
                  _chip('Hot reloads', '${m.hotReloadCount}'),
                  _chip('Hot restarts', '${m.hotRestartCount}'),
                  _chip('Status', statusText),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
    );
  }

  Future<void> _openDocs(BuildContext context) async {
    bool launched = false;
    try {
      launched = await launchUrl(
        _metricsDocs,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Swallow plugin errors (e.g., MissingPluginException) and fall back below.
    }
    if (launched) return;

    Clipboard.setData(ClipboardData(text: _metricsDocs.toString()));
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content:
            Text('Could not open Flutter performance metrics guide. Link copied.'),
      ),
    );
  }
}
