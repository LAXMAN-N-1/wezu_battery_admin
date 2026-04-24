// lib/features/inventory/data/models/stock.dart

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value, [double fallback = 0.0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String _asString(dynamic value, [String fallback = '']) {
  final str = value?.toString();
  if (str == null || str.isEmpty) return fallback;
  return str;
}

bool _asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return fallback;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}

DateTime? _asDate(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

class StockOverview {
  final int totalBatteries;
  final int totalStations;
  final double avgUtilization;
  final int lowStockAlerts;
  final int warehouseCount;
  final int serviceCount;
  final int availableCount;
  final int rentedCount;
  final int maintenanceCount;

  StockOverview({
    required this.totalBatteries,
    required this.totalStations,
    required this.avgUtilization,
    required this.lowStockAlerts,
    required this.warehouseCount,
    required this.serviceCount,
    required this.availableCount,
    required this.rentedCount,
    required this.maintenanceCount,
  });

  factory StockOverview.fromJson(Map<String, dynamic> json) {
    final statusBreakdown = _asMap(json['status_breakdown']);
    return StockOverview(
      totalBatteries: _asInt(
        json['total_batteries'] ?? json['total_count'] ?? json['total'],
      ),
      totalStations: _asInt(json['total_stations']),
      avgUtilization: _asDouble(
        json['avg_utilization'] ?? json['utilization_percentage'],
      ),
      lowStockAlerts: _asInt(json['low_stock_alerts'] ?? json['alerts_count']),
      warehouseCount: _asInt(json['warehouse_count']),
      serviceCount: _asInt(
        json['service_count'] ?? json['service_center_count'],
      ),
      availableCount: _asInt(
        json['available_count'] ?? statusBreakdown['available'],
      ),
      rentedCount: _asInt(json['rented_count'] ?? statusBreakdown['rented']),
      maintenanceCount: _asInt(
        json['maintenance_count'] ?? statusBreakdown['maintenance'],
      ),
    );
  }
}

class LocationStock {
  final String locationName;
  final String locationType;
  final int availableCount;
  final int rentedCount;
  final int maintenanceCount;
  final int totalAssigned;
  final double utilizationPercentage;

  LocationStock({
    required this.locationName,
    required this.locationType,
    required this.availableCount,
    required this.rentedCount,
    required this.maintenanceCount,
    required this.totalAssigned,
    required this.utilizationPercentage,
  });

  factory LocationStock.fromJson(Map<String, dynamic> json) {
    final availableCount = _asInt(json['available_count'] ?? json['available']);
    final rentedCount = _asInt(json['rented_count'] ?? json['rented']);
    final maintenanceCount = _asInt(
      json['maintenance_count'] ?? json['maintenance'],
    );
    final totalAssigned = _asInt(
      json['total_assigned'] ??
          json['total_batteries'] ??
          (availableCount + rentedCount + maintenanceCount),
    );
    return LocationStock(
      locationName: _asString(
        json['location_name'] ?? json['name'],
        'Unknown Location',
      ),
      locationType: _asString(
        json['location_type'] ?? json['type'],
        'WAREHOUSE',
      ).toUpperCase(),
      availableCount: availableCount,
      rentedCount: rentedCount,
      maintenanceCount: maintenanceCount,
      totalAssigned: totalAssigned,
      utilizationPercentage: _asDouble(
        json['utilization_percentage'] ??
            (totalAssigned > 0 ? (availableCount / totalAssigned) * 100 : 0.0),
      ),
    );
  }
}

class StationStockConfig {
  final int maxCapacity;
  final int reorderPoint;
  final int reorderQuantity;
  final String? managerEmail;
  final String? managerPhone;

  StationStockConfig({
    required this.maxCapacity,
    required this.reorderPoint,
    required this.reorderQuantity,
    this.managerEmail,
    this.managerPhone,
  });

  factory StationStockConfig.fromJson(Map<String, dynamic> json) {
    return StationStockConfig(
      maxCapacity: _asInt(json['max_capacity'] ?? json['capacity'], 50),
      reorderPoint: _asInt(json['reorder_point'] ?? json['threshold'], 10),
      reorderQuantity: _asInt(json['reorder_quantity'] ?? json['order_qty'], 20),
      managerEmail: _asString(json['manager_email']).isEmpty
          ? null
          : _asString(json['manager_email']),
      managerPhone: _asString(json['manager_phone']).isEmpty
          ? null
          : _asString(json['manager_phone']),
    );
  }

  Map<String, dynamic> toJson() => {
        'max_capacity': maxCapacity,
        'reorder_point': reorderPoint,
        'reorder_quantity': reorderQuantity,
        'manager_email': managerEmail,
        'manager_phone': managerPhone,
      };
}

class StationStock {
  final int stationId;
  final String stationName;
  final String address;
  final double latitude;
  final double longitude;
  final int availableCount;
  final int rentedCount;
  final int maintenanceCount;
  final int totalAssigned;
  final double utilizationPercentage;
  final bool isLowStock;
  final StationStockConfig? config;

  StationStock({
    required this.stationId,
    required this.stationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.availableCount,
    required this.rentedCount,
    required this.maintenanceCount,
    required this.totalAssigned,
    required this.utilizationPercentage,
    required this.isLowStock,
    this.config,
  });

  factory StationStock.fromJson(Map<String, dynamic> json) {
    final availableCount = _asInt(json['available_count'] ?? json['available']);
    final rentedCount = _asInt(json['rented_count'] ?? json['rented']);
    final maintenanceCount = _asInt(
      json['maintenance_count'] ?? json['maintenance'],
    );
    final totalAssigned = _asInt(
      json['total_assigned'] ??
          json['total_batteries'] ??
          (availableCount + rentedCount + maintenanceCount),
    );
    final configJson = _asMap(json['config']);
    final config = configJson.isEmpty ? null : StationStockConfig.fromJson(configJson);
    final reorderPoint = config?.reorderPoint ?? 10;

    return StationStock(
      stationId: _asInt(json['station_id'] ?? json['id']),
      stationName: _asString(
        json['station_name'] ?? json['name'],
        'Unknown Station',
      ),
      address: _asString(
        json['address'] ?? json['full_address'] ?? json['location'],
      ),
      latitude: _asDouble(json['latitude'] ?? json['lat']),
      longitude: _asDouble(json['longitude'] ?? json['lng']),
      availableCount: availableCount,
      rentedCount: rentedCount,
      maintenanceCount: maintenanceCount,
      totalAssigned: totalAssigned,
      utilizationPercentage: _asDouble(
        json['utilization_percentage'] ??
            (totalAssigned > 0 ? (rentedCount / totalAssigned) * 100 : 0.0),
      ),
      isLowStock: _asBool(
        json['is_low_stock'],
        availableCount <= reorderPoint,
      ),
      config: config,
    );
  }
}

class StockForecast {
  final double avgRentalsPerDay;
  final int projectedDemand30d;
  final int recommendedReorder;
  final DateTime? recommendedDate;
  final int? predictedStockoutDays;

  StockForecast({
    required this.avgRentalsPerDay,
    required this.projectedDemand30d,
    required this.recommendedReorder,
    this.recommendedDate,
    this.predictedStockoutDays,
  });

  factory StockForecast.fromJson(Map<String, dynamic> json) {
    return StockForecast(
      avgRentalsPerDay: _asDouble(
        json['avg_rentals_per_day'] ?? json['avg_rental_per_day'],
      ),
      projectedDemand30d: _asInt(
        json['projected_demand_30d'] ?? json['demand_30d'],
      ),
      recommendedReorder: _asInt(
        json['recommended_reorder'] ?? json['recommended_quantity'],
      ),
      recommendedDate: _asDate(json['recommended_date']),
      predictedStockoutDays: json['predicted_stockout_days'] == null
          ? null
          : _asInt(json['predicted_stockout_days']),
    );
  }
}

class StationStockDetail {
  final StationStock station;
  final StockForecast forecast;
  final List<dynamic> batteries; // For use with All Batteries drawer UI
  final List<double> utilizationTrend;

  StationStockDetail({
    required this.station,
    required this.forecast,
    required this.batteries,
    this.utilizationTrend = const [],
  });

  factory StationStockDetail.fromJson(Map<String, dynamic> json) {
    final root = _asMap(json['data']).isEmpty ? json : _asMap(json['data']);
    final stationJson = _asMap(root['station']).isEmpty
        ? root
        : _asMap(root['station']);
    final forecastJson = _asMap(root['forecast']);
    final trendRaw = _asList(
      root['utilization_trend'] ??
          root['trend'] ??
          _asMap(root['forecast'])['utilization_trend'],
    );
    return StationStockDetail(
      station: StationStock.fromJson(stationJson),
      forecast: StockForecast.fromJson(
        forecastJson.isEmpty ? <String, dynamic>{} : forecastJson,
      ),
      batteries: _asList(root['batteries']),
      utilizationTrend: trendRaw
          .map((e) => _asDouble(e))
          .where((e) => e >= 0)
          .toList(),
    );
  }
}

class StockAlert {
  final int stationId;
  final String stationName;
  final int currentCount;
  final int capacity;
  final int threshold;
  final double utilizationPercentage;

  StockAlert({
    required this.stationId,
    required this.stationName,
    required this.currentCount,
    required this.capacity,
    required this.threshold,
    required this.utilizationPercentage,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      stationId: _asInt(json['station_id'] ?? json['id']),
      stationName: _asString(
        json['station_name'] ?? json['name'],
        'Unknown Station',
      ),
      currentCount: _asInt(
        json['current_count'] ?? json['available_count'] ?? json['available'],
      ),
      capacity: _asInt(json['capacity'] ?? json['max_capacity']),
      threshold: _asInt(json['threshold'] ?? json['reorder_point'], 10),
      utilizationPercentage: _asDouble(
        json['utilization_percentage'] ?? json['capacity_percent'],
      ),
    );
  }
}

class ReorderRequest {
  final String id;
  final int stationId;
  final int requestedQuantity;
  final String status;
  final DateTime createdAt;

  ReorderRequest({
    required this.id,
    required this.stationId,
    required this.requestedQuantity,
    required this.status,
    required this.createdAt,
  });

  factory ReorderRequest.fromJson(Map<String, dynamic> json) {
    return ReorderRequest(
      id: _asString(json['id'], '0'),
      stationId: _asInt(json['station_id'] ?? json['station']),
      requestedQuantity: _asInt(
        json['requested_quantity'] ?? json['quantity'],
      ),
      status: _asString(json['status'], 'pending'),
      createdAt:
          _asDate(json['created_at'] ?? json['created']) ?? DateTime.now(),
    );
  }
}
