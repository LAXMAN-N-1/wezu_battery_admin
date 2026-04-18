import '../models/feature_flag_model.dart';

class FeatureFlagRepository {
  // Simulating local state for demo purposes
  final List<FeatureFlagModel> _mockFlags = [
    FeatureFlagModel(
      key: 'battery_swapping_v2',
      name: 'Enable Battery Swapping v2',
      description: 'Enables the new modular swapping algorithm for v2 stations.',
      isEnabled: true,
      category: FeatureFlagCategory.customerApp,
      affectedApps: ['Customer App', 'IoT Core'],
      lastChangedBy: 'Ahmad (Lead Eng)',
      lastChangedAt: DateTime.now().subtract(const Duration(days: 2)),
      history: [
        FeatureFlagHistoryEntry(
          changedBy: 'Ahmad (Lead Eng)',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          oldValue: false,
          newValue: true,
          comment: 'Initial release of v2 algo',
        ),
      ],
      overrides: {'Production': true, 'Staging': true, 'Dev': true},
    ),
    FeatureFlagModel(
      key: 'maintenance_banner',
      name: 'Show Maintenance Banner',
      description: 'Globally display a maintenance warning on all portals.',
      isEnabled: false,
      category: FeatureFlagCategory.adminPortal,
      affectedApps: ['Admin Portal', 'Dealer Portal', 'Customer App'],
      lastChangedBy: 'System',
      lastChangedAt: DateTime.now().subtract(const Duration(hours: 12)),
      history: [
        FeatureFlagHistoryEntry(
          changedBy: 'System',
          timestamp: DateTime.now().subtract(const Duration(hours: 12)),
          oldValue: true,
          newValue: false,
          comment: 'Scheduled maintenance completed',
        ),
      ],
    ),
     FeatureFlagModel(
      key: 'referral_program',
      name: 'Enable Referral Program',
      description: 'Allow users to invite friends and earn energy credits.',
      isEnabled: true,
      category: FeatureFlagCategory.customerApp,
      affectedApps: ['Customer App'],
      lastChangedBy: 'Sneha (Product)',
      lastChangedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    FeatureFlagModel(
      key: 'new_checkout_flow',
      name: 'New Checkout Flow (A/B)',
      description: 'Testing the 3-step checkout process against legacy 5-step.',
      isEnabled: true,
      category: FeatureFlagCategory.customerApp,
      affectedApps: ['Customer App'],
      lastChangedBy: 'Sneha (Product)',
      lastChangedAt: DateTime.now().subtract(const Duration(days: 5)),
      overrides: {'Production': false, 'Staging': true},
    ),
    FeatureFlagModel(
      key: 'dealer_analytics_v2',
      name: 'Beta Dealer Analytics',
      description: 'Show advanced revenue prediction charts in dealer portal.',
      isEnabled: true,
      category: FeatureFlagCategory.dealerPortal,
      affectedApps: ['Dealer Portal'],
      lastChangedBy: 'Fayaz (Dev)',
      lastChangedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    FeatureFlagModel(
      key: 'iot_live_dashboard',
      name: 'IoT Live Dashboard',
      description: 'Real-time telemetry streaming for battery health monitoring.',
      isEnabled: false,
      category: FeatureFlagCategory.experimental,
      affectedApps: ['Admin Portal'],
      lastChangedBy: 'Ahmad (Lead Eng)',
      lastChangedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  Future<List<FeatureFlagModel>> fetchFlags() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return List.from(_mockFlags);
  }

  Future<bool> toggleFlag(String key, bool value) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // In a real app, you'd send an API call here
    // For this mock, we just return success
    // A 10% chance of failure to demonstrate error handling
    if (DateTime.now().millisecond % 10 == 0) {
      throw Exception('Network timeout while updating flag');
    }
    
    return true;
  }

  Future<FeatureFlagModel> createFlag(FeatureFlagModel flag) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockFlags.add(flag);
    return flag;
  }
}
