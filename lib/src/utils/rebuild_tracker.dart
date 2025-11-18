import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Uses the debug rebuild hook to count dirty widget rebuilds per window.
class RebuildTracker {
  RebuildTracker({this.window = const Duration(seconds: 1)});

  final Duration window;
  final ValueNotifier<int> rebuildsPerWindow = ValueNotifier<int>(0);

  Timer? _timer;
  int _currentRebuilds = 0;
  RebuildDirtyWidgetCallback? _previousDebugHook;

  void start() {
    _timer ??= Timer.periodic(window, (_) {
      rebuildsPerWindow.value = _currentRebuilds;
      _currentRebuilds = 0;
    });
    assert(() {
      _previousDebugHook = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = _handleRebuild;
      return true;
    }());
  }

  void _handleRebuild(Element element, bool builtOnce) {
    _currentRebuilds++;
    _previousDebugHook?.call(element, builtOnce);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    assert(() {
      if (debugOnRebuildDirtyWidget == _handleRebuild) {
        debugOnRebuildDirtyWidget = _previousDebugHook;
      }
      return true;
    }());
  }

  void dispose() {
    stop();
    rebuildsPerWindow.dispose();
  }
}
