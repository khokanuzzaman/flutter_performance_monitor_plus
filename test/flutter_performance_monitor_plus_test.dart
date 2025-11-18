import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_performance_monitor_plus/flutter_performance_monitor_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('network logging stores entries', () {
    final controller = PerformanceMonitorController();
    controller.markAsPrimary();
    controller.logNetworkRequest(
      method: 'GET',
      url: 'https://example.com',
      duration: const Duration(milliseconds: 123),
      statusCode: 200,
    );

    expect(controller.networkLogs.value.length, 1);
    expect(controller.networkLogs.value.first.method, 'GET');
  });

  test('config copyWith overrides values', () {
    const config = PerformanceMonitorConfig();
    final updated = config.copyWith(
      enableFps: false,
      overlayOpacity: 0.5,
      overlayPosition: PerformanceOverlayPosition.bottomLeft,
      enableCpuUsage: false,
      enableHotReloadStats: false,
    );
    expect(updated.enableFps, isFalse);
    expect(updated.overlayOpacity, 0.5);
    expect(updated.overlayPosition, PerformanceOverlayPosition.bottomLeft);
    expect(updated.enableCpuUsage, isFalse);
    expect(updated.enableHotReloadStats, isFalse);
  });
}
