/// Data models for all analytics API responses.
/// Each model has a `fromJson` factory for safe parsing with fallback defaults.

// ─────────────────────────────────────────────
// Overview KPIs  (/api/v1/admin/analytics/overview)
// ─────────────────────────────────────────────

class KpiMetric {
  final String label;
  final dynamic value;
  final double changePercent;
  final bool isPositive;
  final List<double> sparkline;

  const KpiMetric({
    required this.label,
    required this.value,
    this.changePercent = 0,
    this.isPositive = true,
    this.sparkline = const [],
  });

  factory KpiMetric.fromJson(Map<String, dynamic> json) {
    final change = (json['change_percent'] ?? json['changePercent'] ?? 0)
        .toDouble();
    final spark =
        (json['sparkline'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];
    return KpiMetric(
      label: json['label'] ?? json['name'] ?? '',
      value: json['value'] ?? 0,
      changePercent: change,
      isPositive: change >= 0,
      sparkline: spark,
    );
  }
}

class DashboardOverview {
  final KpiMetric totalRevenue;
  final KpiMetric activeRentals;
  final KpiMetric totalUsers;
  final KpiMetric fleetUtilization;
  final KpiMetric activeStations;
  final KpiMetric activeDealers;
  final KpiMetric avgBatteryHealth;
  final KpiMetric openTickets;
  final KpiMetric revenuePerRental;
  final KpiMetric avgSessionDuration;
  final List<KpiMetric> allMetrics;

  const DashboardOverview({
    required this.totalRevenue,
    required this.activeRentals,
    required this.totalUsers,
    required this.fleetUtilization,
    required this.activeStations,
    required this.activeDealers,
    required this.avgBatteryHealth,
    required this.openTickets,
    required this.revenuePerRental,
    required this.avgSessionDuration,
    this.allMetrics = const [],
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    // Handle both flat and nested API shapes
    final metrics = <KpiMetric>[];
    if (json['metrics'] is List) {
      for (final m in json['metrics']) {
        metrics.add(KpiMetric.fromJson(m));
      }
    }

    KpiMetric _extract(
      String key,
      String fallbackLabel,
      dynamic fallbackValue,
    ) {
      // Try from top-level keys first
      if (json.containsKey(key) && json[key] is Map) {
        return KpiMetric.fromJson(json[key]);
      }
      // Try from metrics list by label
      final found = metrics.where(
        (m) => m.label.toLowerCase().contains(key.replaceAll('_', ' ')),
      );
      if (found.isNotEmpty) return found.first;
      // Fallback: use top-level value if present
      if (json.containsKey(key)) {
        return KpiMetric(
          label: fallbackLabel,
          value: json[key],
          changePercent: (json['${key}_change'] ?? 0).toDouble(),
          isPositive: (json['${key}_change'] ?? 0) >= 0,
        );
      }
      return KpiMetric(label: fallbackLabel, value: fallbackValue);
    }

    return DashboardOverview(
      totalRevenue: _extract('total_revenue', 'Total Revenue', 0),
      activeRentals: _extract('active_rentals', 'Active Rentals', 0),
      totalUsers: _extract('total_users', 'Total Users', 0),
      fleetUtilization: _extract('fleet_utilization', 'Fleet Utilization', 0),
      activeStations: _extract('active_stations', 'Active Stations', 0),
      activeDealers: _extract('active_dealers', 'Active Dealers', 0),
      avgBatteryHealth: _extract(
        'avg_battery_health',
        'Avg. Battery Health',
        0,
      ),
      openTickets: _extract('open_tickets', 'Open Tickets', 0),
      revenuePerRental: _extract('revenue_per_rental', 'Revenue per Rental', 0),
      avgSessionDuration: _extract('avg_session_duration', 'Avg. Session', 0),
      allMetrics: metrics,
    );
  }
}

// ─────────────────────────────────────────────
// Trend Data  (/api/v1/admin/analytics/trends)
// ─────────────────────────────────────────────

class TrendPoint {
  final String date;
  final double revenue;
  final double rentals;
  final double users;
  final double batteryHealth;

  const TrendPoint({
    required this.date,
    this.revenue = 0,
    this.rentals = 0,
    this.users = 0,
    this.batteryHealth = 0,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] ?? json['period'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      rentals: (json['rentals'] ?? json['rental_count'] ?? 0).toDouble(),
      users: (json['users'] ?? json['active_users'] ?? 0).toDouble(),
      batteryHealth: (json['battery_health'] ?? json['avg_health'] ?? 0)
          .toDouble(),
    );
  }
}

class TrendData {
  final String period;
  final List<TrendPoint> points;

  const TrendData({required this.period, required this.points});

  factory TrendData.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['data'] ?? json['trends'] ?? json['points'] ?? [];
    return TrendData(
      period: json['period'] ?? 'daily',
      points: (rawPoints as List).map((e) => TrendPoint.fromJson(e)).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Conversion Funnel
// ─────────────────────────────────────────────

class FunnelStage {
  final String name;
  final int count;
  final double conversionRate;
  final double dropOffRate;

  const FunnelStage({
    required this.name,
    required this.count,
    this.conversionRate = 0,
    this.dropOffRate = 0,
  });

  factory FunnelStage.fromJson(Map<String, dynamic> json) {
    return FunnelStage(
      name: json['stage'] ?? json['name'] ?? '',
      count: (json['count'] ?? json['value'] ?? 0).toInt(),
      conversionRate: (json['conversion_rate'] ?? json['conversionRate'] ?? 0)
          .toDouble(),
      dropOffRate: (json['drop_off_rate'] ?? json['dropOffRate'] ?? 0)
          .toDouble(),
    );
  }
}

class ConversionFunnel {
  final List<FunnelStage> stages;

  const ConversionFunnel({required this.stages});

  factory ConversionFunnel.fromJson(Map<String, dynamic> json) {
    final raw = json['stages'] ?? json['funnel'] ?? json['data'] ?? [];
    return ConversionFunnel(
      stages: (raw as List).map((e) => FunnelStage.fromJson(e)).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Battery Health Distribution
// ─────────────────────────────────────────────

class HealthBucket {
  final String category;
  final int count;
  final double percentage;

  const HealthBucket({
    required this.category,
    required this.count,
    required this.percentage,
  });

  factory HealthBucket.fromJson(Map<String, dynamic> json) {
    return HealthBucket(
      category: json['category'] ?? json['range'] ?? json['label'] ?? '',
      count: (json['count'] ?? json['value'] ?? 0).toInt(),
      percentage: (json['percentage'] ?? json['percent'] ?? 0).toDouble(),
    );
  }
}

class BatteryHealthDistribution {
  final List<HealthBucket> buckets;
  final List<HealthBucket> previousBuckets;
  final int totalBatteries;
  final int previousTotal;

  const BatteryHealthDistribution({
    required this.buckets,
    this.totalBatteries = 0,
    this.previousBuckets = const [],
    this.previousTotal = 0,
  });

  factory BatteryHealthDistribution.fromJson(Map<String, dynamic> json) {
    final raw = json['distribution'] ?? json['buckets'] ?? json['data'] ?? [];
    final rawPrevious = json['previous_distribution'] ??
        json['previous'] ??
        json['previous_buckets'] ??
        [];

    return BatteryHealthDistribution(
      buckets: (raw as List).map((e) => HealthBucket.fromJson(e)).toList(),
      totalBatteries: (json['total'] ?? json['total_batteries'] ?? 0).toInt(),
      previousBuckets: (rawPrevious as List)
          .map((e) => HealthBucket.fromJson(e))
          .toList(),
      previousTotal: (json['previous_total'] ?? json['prev_total'] ?? json['total_previous'] ?? 0)
          .toInt(),
    );
  }
}

// ─────────────────────────────────────────────
// User Behavior
// ─────────────────────────────────────────────

class SessionBucket {
  final String range;
  final int count;

  const SessionBucket({required this.range, required this.count});

  factory SessionBucket.fromJson(Map<String, dynamic> json) => SessionBucket(
        range: json['range'] ?? json['label'] ?? '',
        count: (json['count'] ?? json['value'] ?? 0).toInt(),
      );
}

class UserBehavior {
  final double avgSessionDuration;
  final double avgRentalsPerUser;
  final Map<String, dynamic> peakHours;
  final List<List<int>> heatmap; // 7x24 matrix for peak traffic
  final List<SessionBucket> sessionHistogram;
  final Map<String, double> cohortBreakdown; // new vs returning %
  final Map<String, dynamic> raw;

  const UserBehavior({
    this.avgSessionDuration = 0,
    this.avgRentalsPerUser = 0,
    this.peakHours = const {},
    this.heatmap = const [],
    this.sessionHistogram = const [],
    this.cohortBreakdown = const {},
    this.raw = const {},
  });

  factory UserBehavior.fromJson(Map<String, dynamic> json) {
    return UserBehavior(
      avgSessionDuration: (json['avg_session_duration'] ?? 0).toDouble(),
      avgRentalsPerUser: (json['avg_rentals_per_user'] ?? 0).toDouble(),
      peakHours: (json['peak_hours'] is Map) ? json['peak_hours'] : {},
      heatmap: (json['heatmap'] is List)
          ? (json['heatmap'] as List)
              .map<List<int>>((row) => (row as List)
                  .map<int>((e) => (e as num).toInt())
                  .toList())
              .toList()
          : const [],
      sessionHistogram: (json['session_histogram'] is List)
          ? (json['session_histogram'] as List)
              .map((e) => SessionBucket.fromJson(e))
              .toList()
          : const [],
      cohortBreakdown: (json['cohort_breakdown'] is Map)
          ? (json['cohort_breakdown'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            )
          : const {},
      raw: json,
    );
  }
}

// ─────────────────────────────────────────────
// Demand Forecast
// ─────────────────────────────────────────────

class ForecastPoint {
  final String date;
  final double predicted;
  final double? actual;

  const ForecastPoint({
    required this.date,
    required this.predicted,
    this.actual,
  });

  factory ForecastPoint.fromJson(Map<String, dynamic> json) {
    return ForecastPoint(
      date: json['date'] ?? json['period'] ?? '',
      predicted: (json['predicted'] ?? json['forecast'] ?? 0).toDouble(),
      actual: json['actual'] != null
          ? (json['actual'] as num).toDouble()
          : null,
    );
  }
}

class DemandForecast {
  final List<ForecastPoint> points;

  const DemandForecast({required this.points});

  factory DemandForecast.fromJson(Map<String, dynamic> json) {
    final raw = json['forecast'] ?? json['data'] ?? json['points'] ?? [];
    return DemandForecast(
      points: (raw as List).map((e) => ForecastPoint.fromJson(e)).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Revenue By Region
// ─────────────────────────────────────────────

class RegionRevenue {
  final String region;
  final double revenue;
  final int rentalCount;

  const RegionRevenue({
    required this.region,
    required this.revenue,
    this.rentalCount = 0,
  });

  factory RegionRevenue.fromJson(Map<String, dynamic> json) {
    return RegionRevenue(
      region: json['region'] ?? json['name'] ?? json['station'] ?? '',
      revenue: (json['revenue'] ?? json['amount'] ?? 0).toDouble(),
      rentalCount: (json['rental_count'] ?? json['rentals'] ?? 0).toInt(),
    );
  }
}

class RevenueByRegion {
  final List<RegionRevenue> regions;

  const RevenueByRegion({required this.regions});

  factory RevenueByRegion.fromJson(Map<String, dynamic> json) {
    final raw = json['regions'] ?? json['data'] ?? json['revenue'] ?? [];
    return RevenueByRegion(
      regions: (raw as List).map((e) => RegionRevenue.fromJson(e)).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// User Growth
// ─────────────────────────────────────────────

class GrowthPoint {
  final String period;
  final int totalUsers;
  final int newUsers;
  final int returningUsers;

  const GrowthPoint({
    required this.period,
    this.totalUsers = 0,
    this.newUsers = 0,
    this.returningUsers = 0,
  });

  factory GrowthPoint.fromJson(Map<String, dynamic> json) {
    final total = (json['total_users'] ?? json['total'] ?? 0).toInt();
    final newUsers = (json['new_users'] ?? json['new'] ?? 0).toInt();
    final returning = (json['returning_users'] ?? (total - newUsers)).toInt();

    return GrowthPoint(
      period: json['period'] ?? json['date'] ?? json['month'] ?? '',
      totalUsers: total,
      newUsers: newUsers,
      returningUsers: returning < 0 ? 0 : returning,
    );
  }
}

class UserGrowth {
  final String periodType;
  final List<GrowthPoint> points;

  const UserGrowth({required this.periodType, required this.points});

  factory UserGrowth.fromJson(Map<String, dynamic> json) {
    final raw = json['data'] ?? json['growth'] ?? json['points'] ?? [];
    return UserGrowth(
      periodType: json['period'] ?? 'monthly',
      points: (raw as List).map((e) => GrowthPoint.fromJson(e)).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Inventory Status
// ─────────────────────────────────────────────

class InventoryItem {
  final String category;
  final int total;
  final int available;
  final int rented;
  final int maintenance;

  const InventoryItem({
    required this.category,
    this.total = 0,
    this.available = 0,
    this.rented = 0,
    this.maintenance = 0,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      category: json['category'] ?? json['type'] ?? json['name'] ?? '',
      total: (json['total'] ?? 0).toInt(),
      available: (json['available'] ?? json['in_stock'] ?? 0).toInt(),
      rented: (json['rented'] ?? json['in_use'] ?? 0).toInt(),
      maintenance: (json['maintenance'] ?? json['under_maintenance'] ?? 0)
          .toInt(),
    );
  }
}

class InventoryStatus {
  final List<InventoryItem> items;
  final int totalBatteries;
  final int totalAvailable;

  const InventoryStatus({
    required this.items,
    this.totalBatteries = 0,
    this.totalAvailable = 0,
  });

  factory InventoryStatus.fromJson(Map<String, dynamic> json) {
    final raw = json['inventory'] ?? json['items'] ?? json['data'] ?? [];
    return InventoryStatus(
      items: (raw as List).map((e) => InventoryItem.fromJson(e)).toList(),
      totalBatteries: (json['total_batteries'] ?? json['total'] ?? 0).toInt(),
      totalAvailable: (json['total_available'] ?? json['available'] ?? 0)
          .toInt(),
    );
  }
}
// ─────────────────────────────────────────────
// Station Revenue
// ─────────────────────────────────────────────

class StationRevenue {
  final String stationName;
  final double revenue;
  final int rentalCount;
  final double percentage;
  final double avgSessionDuration;
  final List<BatteryTypeRevenue> batteryMix;
  final double utilization;

  const StationRevenue({
    required this.stationName,
    required this.revenue,
    required this.rentalCount,
    this.percentage = 0,
    this.avgSessionDuration = 0,
    this.batteryMix = const [],
    this.utilization = 0,
  });

  factory StationRevenue.fromJson(Map<String, dynamic> json) {
    return StationRevenue(
      stationName: json['station_name'] ?? json['name'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      rentalCount: (json['rental_count'] ?? json['rentals'] ?? 0).toInt(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      avgSessionDuration:
          (json['avg_session_duration'] ?? json['avg_session'] ?? 0)
              .toDouble(),
      batteryMix: (json['battery_mix'] is List)
          ? (json['battery_mix'] as List)
              .map((e) => BatteryTypeRevenue.fromJson(e))
              .toList()
          : const [],
      utilization: (json['utilization'] ?? json['util'] ?? 0).toDouble(),
    );
  }
}

class StationRevenueData {
  final List<StationRevenue> stations;
  final double totalRevenue;

  const StationRevenueData({
    required this.stations,
    required this.totalRevenue,
  });

  factory StationRevenueData.fromJson(Map<String, dynamic> json) {
    final raw = json['stations'] ?? json['data'] ?? [];
    return StationRevenueData(
      stations: (raw as List).map((e) => StationRevenue.fromJson(e)).toList(),
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────
// Battery Type Revenue
// ─────────────────────────────────────────────

class BatteryTypeRevenue {
  final String type;
  final double revenue;
  final double percentage;
  final int rentalCount;

  const BatteryTypeRevenue({
    required this.type,
    required this.revenue,
    required this.percentage,
    required this.rentalCount,
  });

  factory BatteryTypeRevenue.fromJson(Map<String, dynamic> json) {
    return BatteryTypeRevenue(
      type: json['type'] ?? json['category'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      rentalCount: (json['rental_count'] ?? 0).toInt(),
    );
  }
}

class BatteryTypeRevenueData {
  final List<BatteryTypeRevenue> types;
  final List<StationRevenue> stationMix; // reuse StationRevenue for per-station mix

  const BatteryTypeRevenueData({required this.types, this.stationMix = const []});

  factory BatteryTypeRevenueData.fromJson(Map<String, dynamic> json) {
    final raw = json['types'] ?? json['data'] ?? [];
    final stationRaw = json['station_mix'] ?? json['stations'] ?? [];
    return BatteryTypeRevenueData(
      types: (raw as List).map((e) => BatteryTypeRevenue.fromJson(e)).toList(),
      stationMix: (stationRaw as List)
          .map((e) => StationRevenue.fromJson(e))
          .toList(),
    );
  }
}
// ─────────────────────────────────────────────
// Recent Activity
// ─────────────────────────────────────────────

class RecentActivityItem {
  final String title;
  final String description;
  final String time;
  final String type; // 'user', 'rental', 'swap', 'payment', 'alert'
  final Map<String, dynamic> details;
  final String? entityId;
  final String? severity;

  const RecentActivityItem({
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    this.details = const {},
    this.entityId,
    this.severity,
  });

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentActivityItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      time: json['time'] ?? '',
      type: json['type'] ?? 'user',
      details: (json['details'] is Map) ? json['details'] : const {},
      entityId: json['entity_id'],
      severity: json['severity'],
    );
  }
}

class RecentActivityData {
  final List<RecentActivityItem> activities;

  const RecentActivityData({required this.activities});

  factory RecentActivityData.fromJson(Map<String, dynamic> json) {
    final raw = json['activities'] ?? json['data'] ?? [];
    return RecentActivityData(
      activities: (raw as List)
          .map((e) => RecentActivityItem.fromJson(e))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Top Performing Stations
// ─────────────────────────────────────────────

class TopStation {
  final String id;
  final String name;
  final String location;
  final int rentals;
  final double revenue;
  final double utilization;
  final double rating;
  final double availablePercent;
  final double chargingPercent;
  final double offlinePercent;
  final List<double> sparkline;

  const TopStation({
    required this.id,
    required this.name,
    required this.location,
    required this.rentals,
    required this.revenue,
    required this.utilization,
    required this.rating,
    this.availablePercent = 0,
    this.chargingPercent = 0,
    this.offlinePercent = 0,
    this.sparkline = const [],
  });

  factory TopStation.fromJson(Map<String, dynamic> json) {
    return TopStation(
      id: json['id'] ?? json['station_id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      rentals: (json['rentals'] ?? 0).toInt(),
      revenue: (json['revenue'] ?? 0).toDouble(),
      utilization: (json['utilization'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      availablePercent:
          (json['available_percent'] ?? json['available'] ?? 0).toDouble(),
      chargingPercent:
          (json['charging_percent'] ?? json['charging'] ?? 0).toDouble(),
      offlinePercent:
          (json['offline_percent'] ?? json['offline'] ?? 0).toDouble(),
      sparkline: (json['sparkline'] is List)
          ? (json['sparkline'] as List)
              .map((e) => (e as num).toDouble())
              .toList()
          : const [],
    );
  }
}

class TopStationsData {
  final List<TopStation> stations;

  const TopStationsData({required this.stations});

  factory TopStationsData.fromJson(Map<String, dynamic> json) {
    final raw = json['stations'] ?? json['data'] ?? [];
    return TopStationsData(
      stations: (raw as List).map((e) => TopStation.fromJson(e)).toList(),
    );
  }
}
