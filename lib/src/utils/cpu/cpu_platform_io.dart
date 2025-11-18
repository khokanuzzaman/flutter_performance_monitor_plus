import 'dart:io';

/// Very small /proc-based sampler. Returns null if sampling fails or the
/// platform does not expose procfs.
class _CpuSnapshot {
  _CpuSnapshot({
    required this.totalTicks,
    required this.idleTicks,
    required this.processTicks,
  });

  final int totalTicks;
  final int idleTicks;
  final int processTicks;
}

_CpuSnapshot? _readSnapshot() {
  try {
    final statLine =
        File('/proc/stat').readAsLinesSync().firstWhere((line) => line.startsWith('cpu '));
    final cpuParts = statLine.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (cpuParts.length < 5) return null;
    final user = int.parse(cpuParts[1]);
    final nice = int.parse(cpuParts[2]);
    final system = int.parse(cpuParts[3]);
    final idle = int.parse(cpuParts[4]);
    final iowait = cpuParts.length > 5 ? int.parse(cpuParts[5]) : 0;
    final irq = cpuParts.length > 6 ? int.parse(cpuParts[6]) : 0;
    final softirq = cpuParts.length > 7 ? int.parse(cpuParts[7]) : 0;
    final steal = cpuParts.length > 8 ? int.parse(cpuParts[8]) : 0;
    final total = user + nice + system + idle + iowait + irq + softirq + steal;

    final selfStat = File('/proc/self/stat').readAsStringSync();
    final selfParts =
        selfStat.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    // utime (14) and stime (15) are process CPU times in jiffies.
    if (selfParts.length < 16) return null;
    final utime = int.parse(selfParts[13]);
    final stime = int.parse(selfParts[14]);

    return _CpuSnapshot(
      totalTicks: total,
      idleTicks: idle,
      processTicks: utime + stime,
    );
  } catch (_) {
    return null;
  }
}

_CpuSnapshot? _previousSnapshot;

double? getCpuUsagePercent() {
  final current = _readSnapshot();
  if (current == null) return null;
  final previous = _previousSnapshot;
  _previousSnapshot = current;
  if (previous == null) return null;
  final deltaTotal = current.totalTicks - previous.totalTicks;
  final deltaProc = current.processTicks - previous.processTicks;
  if (deltaTotal <= 0 || deltaProc < 0) return null;
  return (deltaProc / deltaTotal) * 100;
}
