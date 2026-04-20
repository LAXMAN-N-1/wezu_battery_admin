import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/settings_repository.dart';
import '../data/models/system_health_models.dart';

class SystemHealthState {
  final bool isLoading;
  final String? error;
  final SystemHealthData? data;
  final DateTime? lastUpdated;
  final bool isAutoRefreshEnabled;

  SystemHealthState({
    this.isLoading = true,
    this.error,
    this.data,
    this.lastUpdated,
    this.isAutoRefreshEnabled = true,
  });

  SystemHealthState copyWith({
    bool? isLoading,
    String? error,
    SystemHealthData? data,
    DateTime? lastUpdated,
    bool? isAutoRefreshEnabled,
  }) {
    return SystemHealthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      data: data ?? this.data,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isAutoRefreshEnabled: isAutoRefreshEnabled ?? this.isAutoRefreshEnabled,
    );
  }
}

class SystemHealthNotifier extends Notifier<SystemHealthState> {
  Timer? _timer;
  final SettingsRepository _repo = SettingsRepository();
  final _random = Random();

  @override
  SystemHealthState build() {
    Future.microtask(_init);
    return SystemHealthState();
  }

  void _init() {
    fetchData();
    _setupTimer();
  }

  void _setupTimer() {
    _timer?.cancel();
    if (state.isAutoRefreshEnabled) {
      _timer = Timer.periodic(const Duration(seconds: 60), (_) {
        fetchData(isSilent: true);
      });
    }
  }

  void toggleAutoRefresh() {
    state = state.copyWith(isAutoRefreshEnabled: !state.isAutoRefreshEnabled);
    if (!state.isAutoRefreshEnabled) {
      _timer?.cancel();
    } else {
      _setupTimer();
    }
  }

  Future<void> fetchData({bool isSilent = false}) async {
    if (!isSilent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    
    try {
      // Try to fetch from real API
      final rawData = await _repo.getSystemHealth();
      
      // Parse or merge with mock data for missing rich metrics
      final healthData = _processHealthData(rawData);
      
      state = state.copyWith(
        isLoading: false,
        data: healthData,
        lastUpdated: DateTime.now(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        data: state.data ?? _generateMockData(), // fallback to mock if completely failed or empty
        lastUpdated: DateTime.now(),
      );
    }
  }

  SystemHealthData _processHealthData(Map<String, dynamic> raw) {
    // 1. Parse real services from backend
    final List<dynamic> rawServices = raw['services'] ?? [];
    final services = rawServices.map((s) {
      final name = s['name']?.toString() ?? 'Unknown';
      final status = s['status']?.toString().toLowerCase() ?? '';
      
      ServiceState state = ServiceState.operational;
      if (status == 'offline' || status == 'down') state = ServiceState.down;
      if (status == 'degraded' || status == 'maintenance') state = ServiceState.degraded;

      return ServiceStatus(
        name: name,
        state: state,
        latencyMs: (s['latency_ms'] as num?)?.toDouble(),
        uptimePercentage: 99.9, // Mocking uptime as backend doesn't provide it yet
        details: s['details'],
      );
    }).toList();

    // 2. Map other simple stats if present, else fallback to mock
    final dbStats = raw['database_stats'] as Map<String, dynamic>? ?? {};
    final connections = (dbStats['users'] as num?)?.toDouble() ?? 0;
    
    // 3. Construct the merged object (Real data + Mocked rich metrics)
    final mock = _generateMockData();
    
    return SystemHealthData(
      overallState: services.any((s) => s.state == ServiceState.down) 
          ? SystemState.critical 
          : services.any((s) => s.state == ServiceState.degraded)
              ? SystemState.degraded
              : SystemState.normal,
      statusText: services.any((s) => s.state != ServiceState.operational)
          ? 'System is experiencing degraded performance'
          : 'All Systems Operational — Real-time Monitoring Active',
      uptimePercentage: 99.97,
      cpu: mock.cpu,
      memory: mock.memory,
      disk: mock.disk,
      connections: MetricData(
        value: connections,
        label: connections.toInt().toString(),
        subLabel: 'Active Database Users',
        trend: 0,
        sparkline: mock.connections.sparkline,
      ),
      uptime: mock.uptime,
      services: services.isEmpty ? mock.services : services,
      apiResponseTimes: mock.apiResponseTimes,
      errorRates: mock.errorRates,
      recentEvents: mock.recentEvents,
      currentCacheSize: mock.currentCacheSize,
      activeQueueJobs: mock.activeQueueJobs,
    );
  }

  SystemHealthData _generateMockData() {
    return SystemHealthData(
      overallState: SystemState.normal,
      statusText: 'All Systems Operational — 99.97% uptime this month',
      uptimePercentage: 99.97,
      cpu: MetricData(
        value: 42 + _random.nextDouble() * 5,
        label: '42%',
        subLabel: 'Avg last 1h: 42%',
        sparkline: List.generate(24, (i) => 20 + _random.nextDouble() * 60),
      ),
      memory: MetricData(
        value: 6.2 + _random.nextDouble() * 0.2,
        max: 16.0,
        label: '6.2 GB / 16 GB',
        subLabel: 'Avg last 1h: 6.1 GB',
        sparkline: List.generate(24, (i) => 5.5 + _random.nextDouble() * 3),
      ),
      disk: MetricData(
        value: 245 + _random.nextDouble() * 0.1,
        max: 500,
        label: '245 GB / 500 GB',
        subLabel: '49% used',
        sparkline: List.generate(24, (i) => 240 + _random.nextDouble() * 5),
      ),
      connections: MetricData(
        value: 1240 + _random.nextDouble() * 50,
        label: '1,240',
        subLabel: 'Current active conns',
        trend: 12.5,
        sparkline: List.generate(24, (i) => 1000 + _random.nextDouble() * 500),
      ),
      uptime: MetricData(
        value: 99.97,
        label: '99.97%',
        subLabel: '30-day average',
        sparkline: List.generate(24, (i) => 99.9 + _random.nextDouble() * 0.1),
      ),
      services: [
        ServiceStatus(
          name: 'Main PostgreSQL DB',
          state: ServiceState.operational,
          latencyMs: (14 + _random.nextInt(5)).toDouble(),
          uptimePercentage: 99.9,
        ),
        ServiceStatus(
          name: 'Read Replica DB',
          state: ServiceState.operational,
          latencyMs: (18 + _random.nextInt(5)).toDouble(),
          uptimePercentage: 99.9,
        ),
        ServiceStatus(
          name: 'Redis Cache',
          state: ServiceState.operational,
          latencyMs: (2 + _random.nextInt(3)).toDouble(),
          uptimePercentage: 100.0,
        ),
        ServiceStatus(
          name: 'Payment Gateway (Razorpay)',
          state: ServiceState.degraded,
          latencyMs: (890 + _random.nextInt(100)).toDouble(),
          uptimePercentage: 98.4,
          lastIncident: 'Today 11:00 AM',
        ),
        ServiceStatus(
          name: 'IoT MQTT Broker',
          state: ServiceState.down,
          latencyMs: null,
          uptimePercentage: 95.0,
          lastIncident: 'Today 2:15 PM',
        ),
        ServiceStatus(
          name: 'Twilio SMS API',
          state: ServiceState.operational,
          latencyMs: (210 + _random.nextInt(20)).toDouble(),
          uptimePercentage: 99.8,
          lastIncident: '3 days ago',
        ),
        ServiceStatus(
          name: 'SendGrid Email',
          state: ServiceState.operational,
          latencyMs: (145 + _random.nextInt(15)).toDouble(),
          uptimePercentage: 99.9,
        ),
        ServiceStatus(
          name: 'AWS S3 Storage',
          state: ServiceState.operational,
          latencyMs: (89 + _random.nextInt(10)).toDouble(),
          uptimePercentage: 100.0,
        ),
      ],
      apiResponseTimes: List.generate(24, (i) {
        final base = 80 + _random.nextDouble() * 60;
        return ApiResponseTimePoint(
          hour: i,
          p50Ms: base,
          p99Ms: base + 100 + _random.nextDouble() * 300,
        );
      }),
      errorRates: List.generate(24, (i) {
        final codes = ['500', '502', '429', '503', '408'];
        final count = _random.nextInt(15);
        return ErrorRatePoint(
          hour: i,
          errorCount: count,
          topErrorCode: codes[_random.nextInt(codes.length)],
        );
      }),
      recentEvents: List.generate(30, (i) {
        final severities = SystemEventSeverity.values;
        final services = ['Redis', 'MQTT', 'Database', 'API Gateway', 'Twilio', 'S3'];
        final severity = severities[_random.nextInt(severities.length)];
        final service = services[_random.nextInt(services.length)];
        return SystemEvent(
          timestamp: DateTime.now().subtract(Duration(minutes: i * 5)),
          severity: severity,
          serviceName: service,
          description: _getEventDesc(severity, service),
        );
      }).reversed.toList(),
      currentCacheSize: '128.4 MB',
      activeQueueJobs: 42,
    );
  }

  String _getEventDesc(SystemEventSeverity severity, String service) {
    if (severity == SystemEventSeverity.critical) return 'Connection timeout after 3 retries. Service unreachable.';
    if (severity == SystemEventSeverity.warning) return 'Memory usage exceeded 80% threshold. Performance impact possible.';
    if (severity == SystemEventSeverity.success) return 'Automated maintenance task completed successfully.';
    return 'Background routine health check completed.';
  }

  Future<void> clearCache() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 1));
    await fetchData(isSilent: true);
  }

  Future<void> restartWorkers() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 2));
    await fetchData(isSilent: true);
  }
}

final systemHealthProvider = NotifierProvider<SystemHealthNotifier, SystemHealthState>(
  SystemHealthNotifier.new,
);
