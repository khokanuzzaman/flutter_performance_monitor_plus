import 'dart:io';

double? getMemoryInMB() {
  try {
    return ProcessInfo.currentRss / (1024 * 1024);
  } catch (_) {
    return null;
  }
}
