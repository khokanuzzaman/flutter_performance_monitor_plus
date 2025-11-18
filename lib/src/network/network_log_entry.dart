class NetworkLogEntry {
  const NetworkLogEntry({
    required this.method,
    required this.url,
    required this.duration,
    required this.timestamp,
    this.statusCode,
    this.error,
  });

  final String method;
  final Uri url;
  final Duration duration;
  final DateTime timestamp;
  final int? statusCode;
  final Object? error;

  bool get isError =>
      error != null || (statusCode != null && statusCode! >= 400);
}
