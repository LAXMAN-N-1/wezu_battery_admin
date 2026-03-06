import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/station_status.dart';
import '../services/station_status_service.dart';
import 'stations_provider.dart';

// -------------------------------------------------------
// Service singleton
// -------------------------------------------------------
final stationStatusServiceProvider = Provider<StationStatusService>(
  (_) => StationStatusService(),
);

// -------------------------------------------------------
// Main stream — list of current statuses for all stations
// Rebuilds when stations change OR maintenance schedules change
// -------------------------------------------------------
final stationStatusStreamProvider = StreamProvider<List<StationStatusEvent>>((
  ref,
) {
  final service = ref.read(stationStatusServiceProvider);
  final stationsAsync = ref.watch(stationsProvider);
  final maintenanceSchedules = ref.watch(maintenanceProvider);

  return stationsAsync.when(
    data: (stations) => service.statusStream(
      stations,
      maintenanceSchedules: maintenanceSchedules,
    ),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// -------------------------------------------------------
// Active alerts notifier
// -------------------------------------------------------
class AlertsNotifier extends StateNotifier<List<StatusAlert>> {
  AlertsNotifier() : super([]);

  // Called every time a new status snapshot arrives.
  // Detects transitions to error/offline and adds an alert.
  void processSnapshot(
    List<StationStatusEvent> current,
    List<StationStatusEvent> previous,
  ) {
    final newAlerts = <StatusAlert>[];
    for (final ev in current) {
      final prev = previous
          .where((p) => p.stationId == ev.stationId)
          .firstOrNull;
      if (prev == null) continue;
      final wentBad =
          (ev.status == StationOperationalStatus.error ||
              ev.status == StationOperationalStatus.offline) &&
          prev.status != ev.status;
      if (wentBad) {
        newAlerts.add(
          StatusAlert(
            stationId: ev.stationId,
            stationName: ev.stationName,
            previousStatus: prev.status,
            newStatus: ev.status,
            timestamp: ev.timestamp,
          ),
        );
      }
    }
    if (newAlerts.isNotEmpty) {
      state = [...newAlerts, ...state];
    }
  }

  void dismiss(int stationId) {
    state = state.where((a) => a.stationId != stationId).toList();
  }

  void dismissAll() => state = [];
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, List<StatusAlert>>(
  (_) => AlertsNotifier(),
);

// -------------------------------------------------------
// Maintenance schedules per station
// -------------------------------------------------------
class MaintenanceNotifier extends StateNotifier<Map<int, MaintenanceSchedule>> {
  final ApiClient _apiClient;

  MaintenanceNotifier(this._apiClient) : super({}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await _apiClient.get('/admin/stations/maintenance/');
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data;
        final map = <int, MaintenanceSchedule>{};
        for (final item in list) {
          final ms = MaintenanceSchedule.fromJson(item as Map<String, dynamic>);
          map[ms.stationId] = ms;
        }
        state = map;
      }
    } catch (_) {}
  }

  Future<void> schedule(MaintenanceSchedule ms) async {
    try {
      final response = await _apiClient.post(
        '/admin/stations/${ms.stationId}/maintenance/',
        data: {
          'maintenance_type': ms.maintenanceType,
          'description': ms.notes,
          'start_time': ms.startTime.toIso8601String(),
          'end_time': ms.endTime.toIso8601String(),
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final saved = MaintenanceSchedule.fromJson(
          response.data as Map<String, dynamic>,
        );
        state = {...state, saved.stationId: saved};
      }
    } catch (_) {}
  }

  Future<void> cancel(int stationId) async {
    try {
      final response = await _apiClient.delete(
        '/admin/stations/$stationId/maintenance/',
      );
      if (response.statusCode == 200) {
        final updated = Map<int, MaintenanceSchedule>.from(state)
          ..remove(stationId);
        state = updated;
      }
    } catch (_) {}
  }
}

final maintenanceProvider =
    StateNotifierProvider<MaintenanceNotifier, Map<int, MaintenanceSchedule>>(
      (ref) => MaintenanceNotifier(ref.read(apiClientProvider)),
    );

// -------------------------------------------------------
// Status history provider (last 50 events)
// -------------------------------------------------------
final statusHistoryProvider = FutureProvider<List<StationStatusEvent>>((
  ref,
) async {
  final service = ref.read(stationStatusServiceProvider);
  return service.loadHistory();
});

// -------------------------------------------------------
// Backend error logs provider — polls /admin/monitoring/errors
// -------------------------------------------------------
final errorLogsProvider = FutureProvider<List<BackendErrorLog>>((ref) async {
  final service = ref.read(stationStatusServiceProvider);
  return service.fetchErrorLogs(limit: 30);
});
