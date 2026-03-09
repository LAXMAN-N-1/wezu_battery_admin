// lib/features/inventory/data/models/stock.dart

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
    return StockOverview(
      totalBatteries: json['total_batteries'] ?? 0,
      totalStations: json['total_stations'] ?? 0,
      avgUtilization: (json['avg_utilization'] as num?)?.toDouble() ?? 0.0,
      lowStockAlerts: json['low_stock_alerts'] ?? 0,
      warehouseCount: json['warehouse_count'] ?? 0,
      serviceCount: json['service_count'] ?? 0,
      availableCount: json['available_count'] ?? 0,
      rentedCount: json['rented_count'] ?? 0,
      maintenanceCount: json['maintenance_count'] ?? 0,
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
    return LocationStock(
      locationName: json['location_name'] ?? '',
      locationType: json['location_type'] ?? '',
      availableCount: json['available_count'] ?? 0,
      rentedCount: json['rented_count'] ?? 0,
      maintenanceCount: json['maintenance_count'] ?? 0,
      totalAssigned: json['total_assigned'] ?? 0,
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0.0,
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
      maxCapacity: json['max_capacity'] ?? 50,
      reorderPoint: json['reorder_point'] ?? 10,
      reorderQuantity: json['reorder_quantity'] ?? 20,
      managerEmail: json['manager_email'],
      managerPhone: json['manager_phone'],
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
    return StationStock(
      stationId: json['station_id'] ?? 0,
      stationName: json['station_name'] ?? 'Unknown Station',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      availableCount: json['available_count'] ?? 0,
      rentedCount: json['rented_count'] ?? 0,
      maintenanceCount: json['maintenance_count'] ?? 0,
      totalAssigned: json['total_assigned'] ?? 0,
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0.0,
      isLowStock: json['is_low_stock'] ?? false,
      config: json['config'] != null ? StationStockConfig.fromJson(json['config']) : null,
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
      avgRentalsPerDay: (json['avg_rentals_per_day'] as num?)?.toDouble() ?? 0.0,
      projectedDemand30d: json['projected_demand_30d'] ?? 0,
      recommendedReorder: json['recommended_reorder'] ?? 0,
      recommendedDate: json['recommended_date'] != null ? DateTime.tryParse(json['recommended_date']) : null,
      predictedStockoutDays: json['predicted_stockout_days'],
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
    return StationStockDetail(
      station: StationStock.fromJson(json['station']),
      forecast: StockForecast.fromJson(json['forecast']),
      batteries: json['batteries'] ?? [],
      utilizationTrend: (json['utilization_trend'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
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
      stationId: json['station_id'],
      stationName: json['station_name'],
      currentCount: json['current_count'],
      capacity: json['capacity'],
      threshold: json['threshold'],
      utilizationPercentage: (json['utilization_percentage'] as num).toDouble(),
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
      id: json['id'],
      stationId: json['station_id'],
      requestedQuantity: json['requested_quantity'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
