import 'dart:convert';
import 'package:intl/intl.dart';

class DaySchedule {
  final String open;
  final String close;
  final bool isOpen;

  DaySchedule({
    required this.open,
    required this.close,
    required this.isOpen,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      open: json['open'] as String? ?? '09:00',
      close: json['close'] as String? ?? '21:00',
      isOpen: json['isOpen'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'open': open,
    'close': close,
    'isOpen': isOpen,
  };
}

class StationHours {
  final Map<String, DaySchedule> schedule;

  StationHours({required this.schedule});

  factory StationHours.fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return StationHours.defaultSchedule();
    }
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      final Map<String, DaySchedule> schedule = {};
      data.forEach((key, value) {
        schedule[key.toLowerCase()] = DaySchedule.fromJson(value);
      });
      return StationHours(schedule: schedule);
    } catch (e) {
      return StationHours.defaultSchedule();
    }
  }

  factory StationHours.defaultSchedule() {
    final Map<String, DaySchedule> schedule = {
      'monday': DaySchedule(open: '08:00', close: '22:00', isOpen: true),
      'tuesday': DaySchedule(open: '08:00', close: '22:00', isOpen: true),
      'wednesday': DaySchedule(open: '08:00', close: '22:00', isOpen: true),
      'thursday': DaySchedule(open: '08:00', close: '22:00', isOpen: true),
      'friday': DaySchedule(open: '08:00', close: '23:00', isOpen: true),
      'saturday': DaySchedule(open: '09:00', close: '23:00', isOpen: true),
      'sunday': DaySchedule(open: '09:00', close: '21:00', isOpen: true),
    };
    return StationHours(schedule: schedule);
  }

  String toJsonString() {
    final Map<String, dynamic> data = {};
    schedule.forEach((key, value) {
      data[key] = value.toJson();
    });
    return json.encode(data);
  }

  StationStatus getStatus({bool is24x7 = false}) {
    if (is24x7) return StationStatus.open;
    final now = DateTime.now();
    final dayName = DateFormat('EEEE', 'en_US').format(now).toLowerCase();
    final daySchedule = schedule[dayName];

    if (daySchedule == null || !daySchedule.isOpen) {
      return StationStatus.closed;
    }

    final nowTime = DateFormat('HH:mm', 'en_US').format(now);
    
    // Simple string comparison for HH:mm is sufficient
    if (nowTime.compareTo(daySchedule.open) < 0 || nowTime.compareTo(daySchedule.close) >= 0) {
      return StationStatus.closed;
    }

    // Check if closing soon (within 30 mins)
    final closeParts = daySchedule.close.split(':');
    final closeTime = DateTime(now.year, now.month, now.day, int.parse(closeParts[0]), int.parse(closeParts[1]));
    
    if (closeTime.difference(now).inMinutes <= 30 && closeTime.isAfter(now)) {
      return StationStatus.closingSoon;
    }

    return StationStatus.open;
  }

  bool isOpen(DateTime time, {bool is24x7 = false}) {
    if (is24x7) return true;
    final dayName = DateFormat('EEEE', 'en_US').format(time).toLowerCase();
    final daySchedule = schedule[dayName];
    if (daySchedule == null || !daySchedule.isOpen) return false;

    final timeStr = DateFormat('HH:mm', 'en_US').format(time);
    // Standard string comparison works for HH:mm format
    return timeStr.compareTo(daySchedule.open) >= 0 &&
        timeStr.compareTo(daySchedule.close) < 0;
  }
}

enum StationStatus {
  open,
  closed,
  closingSoon,
}
