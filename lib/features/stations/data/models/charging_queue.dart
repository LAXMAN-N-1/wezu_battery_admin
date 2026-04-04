
class ChargingQueueResponse {
  final String stationId;
  final int capacity;
  final List<QueueEntry> currentQueue;

  const ChargingQueueResponse({
    required this.stationId,
    required this.capacity,
    required this.currentQueue,
  });

  factory ChargingQueueResponse.fromJson(Map<String, dynamic> json) =>
      ChargingQueueResponse(
        stationId: json['station_id'] as String,
        capacity: json['capacity'] as int? ?? 0,
        currentQueue: (json['current_queue'] as List? ?? [])
            .map((e) => QueueEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class QueueEntry {
  final String batteryId;
  final double currentSoc;
  final int priority;
  final String status;
  final DateTime? estimatedReadyAt;

  const QueueEntry({
    required this.batteryId,
    required this.currentSoc,
    required this.priority,
    required this.status,
    this.estimatedReadyAt,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) => QueueEntry(
        batteryId: json['battery_id'] as String,
        currentSoc: (json['current_soc'] as num?)?.toDouble() ?? 0.0,
        priority: json['priority'] as int? ?? 0,
        status: json['status'] as String? ?? 'waiting',
        estimatedReadyAt: json['estimated_ready_at'] != null
            ? DateTime.parse(json['estimated_ready_at'] as String)
            : null,
      );
}
