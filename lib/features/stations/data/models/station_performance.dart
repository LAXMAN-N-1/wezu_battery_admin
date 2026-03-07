class StationPerformance {
  final int stationId;
  final String stationName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalRentals;
  final double avgDurationMinutes;
  final double totalRevenue;
  final double utilizationRate;
  final List<DailyTrend> dailyTrends;
  final List<PeakHourMetric> peakHours;

  StationPerformance({
    required this.stationId,
    required this.stationName,
    required this.periodStart,
    required this.periodEnd,
    required this.totalRentals,
    required this.avgDurationMinutes,
    required this.totalRevenue,
    required this.utilizationRate,
    required this.dailyTrends,
    required this.peakHours,
  });

  factory StationPerformance.fromJson(Map<String, dynamic> json) {
    return StationPerformance(
      stationId: json['station_id'],
      stationName: json['station_name'],
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      totalRentals: json['total_rentals'],
      avgDurationMinutes: (json['avg_duration_minutes'] as num).toDouble(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      utilizationRate: (json['utilization_rate'] as num).toDouble(),
      dailyTrends: (json['daily_trends'] as List)
          .map((i) => DailyTrend.fromJson(i))
          .toList(),
      peakHours: (json['peak_hours'] as List)
          .map((i) => PeakHourMetric.fromJson(i))
          .toList(),
    );
  }
}

class DailyTrend {
  final String date;
  final int rentals;
  final double revenue;

  DailyTrend({
    required this.date,
    required this.rentals,
    required this.revenue,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: json['date'],
      rentals: json['rentals'],
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class PeakHourMetric {
  final int hour;
  final int rentalCount;

  PeakHourMetric({
    required this.hour,
    required this.rentalCount,
  });

  factory PeakHourMetric.fromJson(Map<String, dynamic> json) {
    return PeakHourMetric(
      hour: json['hour'],
      rentalCount: json['rental_count'],
    );
  }
}

class StationRanking {
  final int stationId;
  final String stationName;
  final double metricValue;
  final int rank;

  StationRanking({
    required this.stationId,
    required this.stationName,
    required this.metricValue,
    required this.rank,
  });

  factory StationRanking.fromJson(Map<String, dynamic> json) {
    return StationRanking(
      stationId: json['station_id'],
      stationName: json['station_name'],
      metricValue: (json['metric_value'] as num).toDouble(),
      rank: json['rank'],
    );
  }
}
