/// Data Transfer Object for Notification Settings.
///
/// Maps to individual key-value pairs in the generic settings API.
/// Email recipients are stored as a comma-separated string on the backend.
class NotificationSettingsModel {
  final List<String> alertEmailRecipients;
  final bool notifyOnNewUser;
  final bool notifyOnFailedPayment;
  final bool notifyOnSecurityAlert;
  final bool notifyOnSystemError;
  final bool dailySummaryEnabled;
  final String dailySummaryTime;
  final bool weeklyAnalyticsEnabled;
  final String weeklyAnalyticsDay;

  const NotificationSettingsModel({
    this.alertEmailRecipients = const [],
    this.notifyOnNewUser = false,
    this.notifyOnFailedPayment = false,
    this.notifyOnSecurityAlert = true,
    this.notifyOnSystemError = false,
    this.dailySummaryEnabled = false,
    this.dailySummaryTime = '09:00',
    this.weeklyAnalyticsEnabled = false,
    this.weeklyAnalyticsDay = 'Monday',
  });

  /// Create a copy with modified fields.
  NotificationSettingsModel copyWith({
    List<String>? alertEmailRecipients,
    bool? notifyOnNewUser,
    bool? notifyOnFailedPayment,
    bool? notifyOnSecurityAlert,
    bool? notifyOnSystemError,
    bool? dailySummaryEnabled,
    String? dailySummaryTime,
    bool? weeklyAnalyticsEnabled,
    String? weeklyAnalyticsDay,
  }) {
    return NotificationSettingsModel(
      alertEmailRecipients: alertEmailRecipients ?? this.alertEmailRecipients,
      notifyOnNewUser: notifyOnNewUser ?? this.notifyOnNewUser,
      notifyOnFailedPayment: notifyOnFailedPayment ?? this.notifyOnFailedPayment,
      notifyOnSecurityAlert: notifyOnSecurityAlert ?? this.notifyOnSecurityAlert,
      notifyOnSystemError: notifyOnSystemError ?? this.notifyOnSystemError,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      dailySummaryTime: dailySummaryTime ?? this.dailySummaryTime,
      weeklyAnalyticsEnabled: weeklyAnalyticsEnabled ?? this.weeklyAnalyticsEnabled,
      weeklyAnalyticsDay: weeklyAnalyticsDay ?? this.weeklyAnalyticsDay,
    );
  }
}
