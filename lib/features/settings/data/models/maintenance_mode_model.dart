/// Data Transfer Object for Maintenance Mode settings.
///
/// Maps to individual key-value pairs in the generic settings API.
class MaintenanceModeModel {
  final bool isEnabled;
  final String maintenanceMessage;
  final String expectedEndTime; // ISO 8601 or 'yyyy-MM-dd HH:mm' string

  const MaintenanceModeModel({
    this.isEnabled = false,
    this.maintenanceMessage = '',
    this.expectedEndTime = '',
  });

  /// Create a copy with modified fields.
  MaintenanceModeModel copyWith({
    bool? isEnabled,
    String? maintenanceMessage,
    String? expectedEndTime,
  }) {
    return MaintenanceModeModel(
      isEnabled: isEnabled ?? this.isEnabled,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      expectedEndTime: expectedEndTime ?? this.expectedEndTime,
    );
  }
}
