import 'dart:async';

import 'package:http/http.dart' as http;

import '../core/performance_monitor_controller.dart';

/// A drop-in HTTP client that reports request metadata to the performance monitor.
class MonitoredHttpClient extends http.BaseClient {
  MonitoredHttpClient({
    http.Client? baseClient,
    PerformanceMonitorController? controller,
  }) : _inner = baseClient ?? http.Client(),
       _controller = controller;

  final http.Client _inner;
  final PerformanceMonitorController? _controller;

  PerformanceMonitorController? get _activeController =>
      _controller ?? PerformanceMonitorController.primary;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startedAt = DateTime.now();
    try {
      final response = await _inner.send(request);
      _log(
        request.method,
        request.url,
        duration: DateTime.now().difference(startedAt),
        statusCode: response.statusCode,
      );
      return response;
    } catch (error) {
      _log(
        request.method,
        request.url,
        duration: DateTime.now().difference(startedAt),
        error: error,
      );
      rethrow;
    }
  }

  void _log(
    String method,
    Uri url, {
    required Duration duration,
    int? statusCode,
    Object? error,
  }) {
    _activeController?.logNetworkRequest(
      method: method,
      url: url.toString(),
      statusCode: statusCode,
      duration: duration,
      error: error,
    );
  }

  @override
  void close() => _inner.close();
}
