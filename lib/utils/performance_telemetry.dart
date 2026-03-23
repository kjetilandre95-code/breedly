import 'package:flutter/foundation.dart';

/// Lightweight in-app telemetry for debug visibility.
class PerformanceTelemetry {
  PerformanceTelemetry._();

  static final Map<String, int> _lastExecutionMs = <String, int>{};

  static void trackElapsed({
    required String key,
    required Stopwatch stopwatch,
    required String logLabel,
  }) {
    final elapsed = stopwatch.elapsedMilliseconds;
    _lastExecutionMs[key] = elapsed;
    if (kDebugMode) {
      debugPrint('[PERF] $logLabel took ${elapsed}ms.');
    }
  }

  static int? lastExecutionMs(String key) => _lastExecutionMs[key];

  static Map<String, int> allLastExecutionMs() =>
      Map<String, int>.unmodifiable(_lastExecutionMs);
}
