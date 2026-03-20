import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  void showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) {
    debugPrint('NOTIFICATION: [$id] $title - $body');
    // In a real app, this would use flutter_local_notifications
  }
}
