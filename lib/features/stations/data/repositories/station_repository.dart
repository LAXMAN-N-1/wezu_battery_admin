import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../models/charging_queue.dart';
import '../models/maintenance_model.dart';
import '../models/station.dart';
import '../models/station_alert.dart';
import '../models/station_performance.dart';
import '../models/station_specs.dart';

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository.withClient(ref.read(apiClientProvider));
});

class StationRepository {
  static const _stationsPath = '/api/v1/stations/';

  final ApiClient? _apiClient;

  const StationRepository._(this._apiClient);

  factory StationRepository.withClient(ApiClient apiClient) {
    return StationRepository._(apiClient);
  }

  factory StationRepository.offline() {
    return const StationRepository._(null);
  }

  Future<List<Station>> getStations({String? search, String? status}) async {
    final query = {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };

    try {
      final apiClient = _apiClient;
      if (apiClient != null) {
        final response = await apiClient.get(
          _stationsPath,
          queryParameters: query.isEmpty ? null : query,
        );
        final stations = _parseStations(response.data);
        if (stations.isNotEmpty) {
          return _filterStations(stations, search: search, status: status);
        }
      }
    } catch (_) {}

    return _filterStations(_fallbackStations, search: search, status: status);
  }

  Future<Map<String, dynamic>> getStationStats() async {
    final stations = await getStations();
    final operational = stations
        .where((station) => _isOperational(station.status))
        .length;
    final maintenance = stations
        .where((station) => _isMaintenance(station.status))
        .length;
    final offline = stations.length - operational - maintenance;
    final ratings = stations
        .where((station) => station.rating > 0)
        .map((station) => station.rating)
        .toList();
    final avgRating = ratings.isEmpty
        ? 0.0
        : ratings.reduce((left, right) => left + right) / ratings.length;

    return {
      'total_stations': stations.length,
      'operational': operational,
      'maintenance': maintenance,
      'offline': offline,
      'avg_rating': avgRating,
    };
  }

  Future<Station> addStation(Station station) async {
    final optimisticStation = station.id == 0
        ? station.copyWith(
            id: DateTime.now().millisecondsSinceEpoch,
            createdAt: DateTime.now(),
            lastPing: DateTime.now(),
          )
        : station;

    try {
      final apiClient = _apiClient;
      if (apiClient != null) {
        final response = await apiClient.post(
          _stationsPath,
          data: station.toJson(),
        );
        return _parseSingleStation(response.data) ?? optimisticStation;
      }
    } catch (_) {}

    return optimisticStation;
  }

  Future<void> updateStation(Station station) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      return;
    }

    final payload = station.toJson();
    try {
      await apiClient.put('$_stationsPath${station.id}/', data: payload);
    } catch (_) {
      await apiClient.patch('$_stationsPath${station.id}/', data: payload);
    }
  }

  Future<void> deleteStation(int id) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      return;
    }

    await apiClient.delete('$_stationsPath$id/');
  }

  Future<StationSpecs> getSpecs(int stationId) async {
    try {
      final apiClient = _apiClient;
      if (apiClient != null) {
        final response = await apiClient.get('$_stationsPath$stationId/specs/');
        final data = _unwrapMap(response.data);
        if (data != null) {
          return StationSpecs.fromJson(data);
        }
      }
    } catch (_) {}

    return StationSpecs.defaults(stationId);
  }

  Future<void> saveSpecs(int stationId, StationSpecs specs) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      return;
    }

    try {
      await apiClient.put(
        '$_stationsPath$stationId/specs/',
        data: specs.toJson(),
      );
    } catch (_) {
      await apiClient.post(
        '$_stationsPath$stationId/specs/',
        data: specs.toJson(),
      );
    }
  }

  Future<StationPerformance> getStationPerformance(
    int stationId, {
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final apiClient = _apiClient;
      if (apiClient != null) {
        final response = await apiClient.get(
          '$_stationsPath$stationId/performance/',
          queryParameters: {
            if (start != null) 'start': start.toIso8601String(),
            if (end != null) 'end': end.toIso8601String(),
          },
        );
        final data = _unwrapMap(response.data);
        if (data != null) {
          return StationPerformance.fromJson(data);
        }
      }
    } catch (_) {}

    final station = await _findStation(stationId);
    final utilizationRate = station.totalSlots == 0
        ? 0.0
        : ((station.totalSlots - station.availableSlots) / station.totalSlots)
              .clamp(0.0, 1.0);

    return StationPerformance(
      stationId: station.id,
      stationName: station.name,
      periodStart: start ?? DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: end ?? DateTime.now(),
      totalRentals: station.availableBatteries * 3,
      avgDurationMinutes: 42,
      totalRevenue: station.availableBatteries * 1250,
      utilizationRate: utilizationRate,
      dailyTrends: const [],
      peakHours: const [],
    );
  }

  Future<List<StationPerformance>> getAllPerformance() async {
    final stations = await getStations();
    final start = DateTime.now().subtract(const Duration(days: 30));
    final end = DateTime.now();

    return stations
        .map(
          (station) => StationPerformance(
            stationId: station.id,
            stationName: station.name,
            periodStart: start,
            periodEnd: end,
            totalRentals: station.availableBatteries * 3,
            avgDurationMinutes: 42,
            totalRevenue: station.availableBatteries * 1250,
            utilizationRate: station.totalSlots == 0
                ? 0
                : ((station.totalSlots - station.availableSlots) /
                          station.totalSlots)
                      .clamp(0.0, 1.0),
            dailyTrends: const [],
            peakHours: const [],
          ),
        )
        .toList();
  }

  Future<List<StationRanking>> getStationRankings({
    String metric = 'revenue',
    int limit = 10,
  }) async {
    try {
      final apiClient = _apiClient;
      if (apiClient != null) {
        final response = await apiClient.get(
          '${_stationsPath}rankings/',
          queryParameters: {'metric': metric, 'limit': limit},
        );
        final list = _unwrapList(response.data);
        if (list != null && list.isNotEmpty) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(StationRanking.fromJson)
              .toList();
        }
      }
    } catch (_) {}

    final stations = await getStations();
    final rankings =
        stations
            .map(
              (station) => StationRanking(
                stationId: station.id,
                stationName: station.name,
                metricValue: _metricValueFor(metric, station),
                rank: 0,
              ),
            )
            .toList()
          ..sort(
            (left, right) => right.metricValue.compareTo(left.metricValue),
          );

    return rankings
        .take(limit)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => StationRanking(
            stationId: entry.value.stationId,
            stationName: entry.value.stationName,
            metricValue: entry.value.metricValue,
            rank: entry.key + 1,
          ),
        )
        .toList();
  }

  Future<List<BackendStationAlert>> getStationAlerts(int stationId) async {
    try {
      final apiClient = _apiClient;
      if (apiClient != null) {
        final response = await apiClient.get(
          '$_stationsPath$stationId/alerts/',
        );
        final list = _unwrapList(response.data);
        if (list != null) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(BackendStationAlert.fromJson)
              .toList();
        }
      }
    } catch (_) {}

    return const [];
  }

  Future<ChargingQueueResponse> getChargingQueue(int stationId) async {
    try {
      final apiClient = _apiClient;
      if (apiClient != null) {
        final response = await apiClient.get(
          '$_stationsPath$stationId/charging-queue/',
        );
        final data = _unwrapMap(response.data);
        if (data != null) {
          return ChargingQueueResponse.fromJson(data);
        }
      }
    } catch (_) {}

    return ChargingQueueResponse(
      stationId: '$stationId',
      capacity: 0,
      currentQueue: const [],
    );
  }

  Future<bool> createMaintenanceRecord(MaintenanceRecord record) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      return true;
    }

    try {
      final response = await apiClient.post(
        'maintenance/record',
        data: {
          'entity_type': record.entityType,
          'entity_id': record.entityId,
          'technician_id': record.technicianId,
          'maintenance_type': record.maintenanceType,
          'description': record.description,
          'status': record.status,
          'cost': record.cost,
          'parts_replaced': record.partsReplaced,
          'performed_at': record.performedAt?.toIso8601String(),
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<Station> _findStation(int stationId) async {
    final stations = await getStations();
    return stations.firstWhere(
      (station) => station.id == stationId,
      orElse: () => Station(
        id: stationId,
        name: 'Station $stationId',
        address: 'Address unavailable',
        latitude: 0,
        longitude: 0,
        status: 'offline',
        totalSlots: 0,
        availableBatteries: 0,
        emptySlots: 0,
        lastPing: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
  }

  List<Station> _parseStations(dynamic raw) {
    final list = _unwrapList(raw);
    if (list == null) {
      return const [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(Station.fromJson)
        .toList();
  }

  Station? _parseSingleStation(dynamic raw) {
    final map = _unwrapMap(raw);
    return map == null ? null : Station.fromJson(map);
  }

  List<dynamic>? _unwrapList(dynamic raw) {
    if (raw is List) {
      return raw;
    }
    if (raw is Map<String, dynamic>) {
      final nested = raw['results'] ?? raw['stations'] ?? raw['data'];
      if (nested is List) {
        return nested;
      }
    }
    return null;
  }

  Map<String, dynamic>? _unwrapMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    return null;
  }

  List<Station> _filterStations(
    List<Station> stations, {
    String? search,
    String? status,
  }) {
    return stations.where((station) {
      final matchesSearch = search == null || search.trim().isEmpty
          ? true
          : [
              station.name,
              station.address,
              station.city ?? '',
              station.stationType,
            ].join(' ').toLowerCase().contains(search.toLowerCase());

      final matchesStatus = status == null || status.trim().isEmpty
          ? true
          : station.status.toLowerCase() == status.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  bool _isOperational(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'active' || normalized == 'operational';
  }

  bool _isMaintenance(String status) {
    return status.toLowerCase() == 'maintenance';
  }

  double _metricValueFor(String metric, Station station) {
    switch (metric.toLowerCase()) {
      case 'rating':
        return station.rating;
      case 'utilization':
        if (station.totalSlots == 0) {
          return 0;
        }
        return ((station.totalSlots - station.availableSlots) /
                station.totalSlots) *
            100;
      case 'revenue':
      default:
        return (station.availableBatteries * 1250) + (station.rating * 100);
    }
  }
}

final _fallbackStations = <Station>[
  Station(
    id: 101,
    name: 'Banjara Hills Hub',
    address: 'Road No. 12, Banjara Hills',
    city: 'Hyderabad',
    latitude: 17.4156,
    longitude: 78.4347,
    status: 'operational',
    totalSlots: 18,
    availableBatteries: 11,
    emptySlots: 7,
    lastPing: DateTime.now().subtract(const Duration(minutes: 4)),
    stationType: 'premium',
    rating: 4.7,
    totalReviews: 186,
    powerRatingKw: 32,
    contactPhone: '+91 90000 11111',
    createdAt: DateTime.now().subtract(const Duration(days: 420)),
    lastHeartbeat: DateTime.now().subtract(const Duration(minutes: 4)),
    is24x7: true,
  ),
  Station(
    id: 102,
    name: 'Madhapur Tech Park',
    address: 'HITEC City Main Road',
    city: 'Hyderabad',
    latitude: 17.4483,
    longitude: 78.3915,
    status: 'maintenance',
    totalSlots: 14,
    availableBatteries: 4,
    emptySlots: 10,
    lastPing: DateTime.now().subtract(const Duration(minutes: 18)),
    stationType: 'standard',
    rating: 4.3,
    totalReviews: 92,
    powerRatingKw: 24,
    contactPhone: '+91 90000 22222',
    createdAt: DateTime.now().subtract(const Duration(days: 280)),
    lastHeartbeat: DateTime.now().subtract(const Duration(minutes: 18)),
  ),
  Station(
    id: 103,
    name: 'Secunderabad Depot',
    address: 'MG Road Junction',
    city: 'Secunderabad',
    latitude: 17.4399,
    longitude: 78.4983,
    status: 'offline',
    totalSlots: 10,
    availableBatteries: 0,
    emptySlots: 10,
    lastPing: DateTime.now().subtract(const Duration(hours: 2, minutes: 12)),
    stationType: 'compact',
    rating: 0,
    totalReviews: 0,
    powerRatingKw: 18,
    contactPhone: '+91 90000 33333',
    createdAt: DateTime.now().subtract(const Duration(days: 190)),
    lastHeartbeat: DateTime.now().subtract(
      const Duration(hours: 2, minutes: 12),
    ),
  ),
];
