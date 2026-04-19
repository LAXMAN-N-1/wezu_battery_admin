enum SystemState { normal, degraded, critical, maintenance }

enum ServiceState { operational, degraded, down }

enum SystemEventSeverity { info, warning, critical, success }

class SystemHealthData {
  final SystemState overallState;
  final String statusText;
  final double uptimePercentage;
  final MetricData cpu;
  final MetricData memory;
  final MetricData disk;
  final MetricData connections;
  final MetricData uptime;
  final List<ServiceStatus> services;
  final List<ApiResponseTimePoint> apiResponseTimes;
  final List<ErrorRatePoint> errorRates;
  final List<SystemEvent> recentEvents;
  final String currentCacheSize;
  final int activeQueueJobs;

  SystemHealthData({
    required this.overallState,
    required this.statusText,
    required this.uptimePercentage,
    required this.cpu,
    required this.memory,
    required this.disk,
    required this.connections,
    required this.uptime,
    required this.services,
    this.apiResponseTimes = const [],
    this.errorRates = const [],
    this.recentEvents = const [],
    this.currentCacheSize = '128.4 MB',
    this.activeQueueJobs = 0,
  });
}

class SystemEvent {
  final DateTime timestamp;
  final SystemEventSeverity severity;
  final String serviceName;
  final String description;

  SystemEvent({
    required this.timestamp,
    required this.severity,
    required this.serviceName,
    required this.description,
  });
}

class MetricData {
  final double value; // 0 to max
  final double max;
  final String label; // Main display text, e.g., "42%" or "6.2 GB"
  final String subLabel; // Sub-display text, e.g., "Avg last 1h: 42%"
  final List<double> sparkline; // 24 hourly data points
  final double? trend; // Percentage change (positive or negative)

  MetricData({
    required this.value,
    this.max = 100,
    required this.label,
    required this.subLabel,
    this.sparkline = const [],
    this.trend,
  });
}

class ServiceStatus {
  final String name;
  final ServiceState state;
  final double? latencyMs;
  final double uptimePercentage;
  final String? lastIncident;
  final String? details;

  ServiceStatus({
    required this.name,
    required this.state,
    this.latencyMs,
    required this.uptimePercentage,
    this.lastIncident,
    this.details,
  });
}

/// A single hourly data point for API response time chart
class ApiResponseTimePoint {
  final int hour; // 0-23
  final double p50Ms; // median latency
  final double p99Ms; // 99th percentile latency

  ApiResponseTimePoint({
    required this.hour,
    required this.p50Ms,
    required this.p99Ms,
  });
}

/// A single hourly data point for error rate chart
class ErrorRatePoint {
  final int hour; // 0-23
  final int errorCount;
  final String topErrorCode; // e.g., "502", "429"

  ErrorRatePoint({
    required this.hour,
    required this.errorCount,
    this.topErrorCode = '500',
  });
}
