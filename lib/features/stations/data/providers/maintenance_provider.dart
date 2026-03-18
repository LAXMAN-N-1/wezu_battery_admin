import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/maintenance_event.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/notification_service.dart';

part 'maintenance_provider.g.dart';

@riverpod
class MaintenanceNotifier extends _$MaintenanceNotifier {
  @override
  FutureOr<List<MaintenanceEvent>> build() async {
    return _fetchEvents();
  }

  Future<List<MaintenanceEvent>> _fetchEvents() async {
    try {
      final client = ref.read(apiClientProvider);
      // Fixed path to match verified backend endpoint
      final response = await client.get('maintenance/history');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // Map MaintenanceRecord (Backend) to MaintenanceEvent (Frontend)
        return data.map((json) {
          final performedAtStr = json['performed_at'];
          final performedAt = performedAtStr != null 
              ? DateTime.parse(performedAtStr) 
              : DateTime.now();
          return MaintenanceEvent(
            id: json['id']?.toString() ?? '',
            stationId: (json['entity_id'] as num?)?.toInt() ?? 0,
            stationName: 'Station ${json['entity_id']}', 
            title: json['description'] as String? ?? 'Maintenance',
            description: json['description'] as String? ?? '',
            startTime: performedAt,
            endTime: performedAt.add(const Duration(hours: 1)),
            status: _mapBackendStatus(json['status']),
            type: _mapBackendType(json['maintenance_type']),
            assignedCrew: json['technician_id'] != null 
                ? 'Technician ${json['technician_id']}' 
                : 'Unassigned',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching maintenance events: $e');
    }
    return []; 
  }

  MaintenanceStatus _mapBackendStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed': return MaintenanceStatus.completed;
      case 'in_progress': return MaintenanceStatus.inProgress;
      case 'cancelled': return MaintenanceStatus.cancelled;
      case 'scheduled': return MaintenanceStatus.scheduled;
      default: return MaintenanceStatus.scheduled;
    }
  }

  MaintenanceType _mapBackendType(String? type) {
    switch (type?.toLowerCase()) {
      case 'routine':
      case 'preventive': return MaintenanceType.routine;
      case 'repair':
      case 'corrective': return MaintenanceType.repair;
      case 'emergency': return MaintenanceType.emergency;
      case 'inspection': return MaintenanceType.inspection;
      default: return MaintenanceType.routine;
    }
  }

  bool _hasConflict(MaintenanceEvent event, {String? excludeId}) {
    final currentEvents = state.value ?? [];
    return currentEvents.any((e) {
      if (e.id == excludeId) return false;
      if (e.stationId != event.stationId) return false;
      
      // Check for overlap: (StartA < EndB) and (EndA > StartB)
      final overlap = event.startTime.isBefore(e.endTime) && event.endTime.isAfter(e.startTime);
      return overlap;
    });
  }

  final List<String> _auditLog = [];
  List<String> get auditLog => List.unmodifiable(_auditLog);

  void _log(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    _auditLog.add('[$timestamp] $message');
    debugPrint('AUDIT: $message');
  }

  Future<void> addEvent(MaintenanceEvent event) async {
    if (_hasConflict(event)) {
      throw Exception('Maintenance conflict: Another task is already scheduled for this station during this time.');
    }
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      // Corrected path and payload to match MaintenanceRecordCreate
      await client.post('maintenance/record', data: {
        'entity_type': 'station',
        'entity_id': event.stationId,
        'maintenance_type': event.type.name,
        'description': event.title.isNotEmpty ? event.title : 'Maintenance',
        'status': event.status.name,
        'cost': 0.0,
        'performed_at': event.startTime.toIso8601String(), // Send the intended date
      });
      
      _log('Added maintenance event: ${event.title} for ${event.stationName}');
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateEvent(MaintenanceEvent event) async {
    if (_hasConflict(event, excludeId: event.id)) {
      throw Exception('Maintenance conflict: Another task is already scheduled for this station during this time.');
    }
    state = const AsyncValue.loading();
    try {
      // NOTE: Backend currently only supports creating/listing records. 
      // Update endpoint is not yet defined in the official spec.
      // Re-creating the record as a workaround or showing a message.
      throw Exception('Updating maintenance status is not yet supported by the backend.');
      
      /*
      final client = ref.read(apiClientProvider);
      await client.put('admin/stations/${event.stationId}/maintenance/${event.id}', 
        queryParameters: {'status': event.status.name},
      );
      
      _log('Updated maintenance event status: ${event.title}');
      ref.invalidateSelf();
      */
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEvent(String id) async {
    state = const AsyncValue.loading();
    try {
      // NOTE: Backend currently does not expose a delete endpoint for maintenance records.
      throw Exception('Deleting maintenance records is not yet supported by the backend.');
      /*
      final client = ref.read(apiClientProvider);
      final eventObj = (state.value ?? []).firstWhere((e) => e.id == id);
      await client.delete('admin/stations/${eventObj.stationId}/maintenance/$id');
      
      _log('Deleted maintenance event: $id');
      ref.invalidateSelf();
      */
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void checkOverdueTasks() {
    final currentEvents = state.value ?? [];
    final now = DateTime.now();
    bool hasOverdue = false;

    for (final event in currentEvents) {
      if (event.status == MaintenanceStatus.scheduled && 
          event.startTime.isBefore(now.subtract(const Duration(minutes: 5)))) {
        // Task is overdue to START (5 min grace period)
        hasOverdue = true;
        _log('OVERDUE ALERT: Task "${event.title}" for ${event.stationName} missed its start time!');
        
        NotificationService().showInstantNotification(
          id: '${event.id}_overdue'.hashCode,
          title: '⚠️ OVERDUE: ${event.stationName}',
          body: 'Maintenance task "${event.title}" was scheduled to start at ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}.',
        );
      }
    }
    
    if (hasOverdue) {
      ref.notifyListeners();
    }
  }
}
