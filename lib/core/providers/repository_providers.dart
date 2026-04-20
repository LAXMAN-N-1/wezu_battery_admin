/// Central Riverpod providers for all feature repositories.
///
/// Views should use these providers (via `ref.watch` / `ref.read`) instead of
/// instantiating repositories with `Repository()` directly.  This gives us:
///   • A single shared instance per repository (avoids duplicate objects)
///   • Consistent DI of [ApiClient]
///   • Repository-level caching becomes possible in Phase 3
///   • Full testability via provider overrides
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

// ── Feature repositories ────────────────────────────────────────────────────
import '../../features/rentals/data/repositories/rental_repository.dart';
import '../../features/inventory/data/repositories/inventory_repository.dart';
import '../../features/inventory/data/repositories/audit_trail_repository.dart';
import '../../features/dealers/data/repositories/dealer_repository.dart';
import '../../features/finance/data/repositories/finance_repository.dart';
import '../../features/logistics/data/repositories/logistics_repository.dart';
import '../../features/bess/data/repositories/bess_repository.dart';
import '../../features/fleet_ops/data/repositories/fleet_ops_repository.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';
import '../../features/support/data/repositories/support_repository.dart';
import '../../features/audit/data/repositories/audit_repository.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../../features/users/data/repositories/user_repository.dart';
import '../../features/users/data/repositories/role_repository.dart';
import '../../features/users/data/repositories/kyc_repository.dart';
import '../../features/users/data/repositories/audit_log_repository.dart';
import '../../features/users/data/repositories/analytics_repository.dart'
    as user_analytics;
import '../../features/battery_health/data/repositories/health_repository.dart';

// ── Rental ───────────────────────────────────────────────────────────────────
final rentalRepositoryProvider = Provider<RentalRepository>((ref) {
  return RentalRepository(ref.read(apiClientProvider));
});

// ── Inventory ────────────────────────────────────────────────────────────────
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.read(apiClientProvider));
});

final auditTrailRepositoryProvider = Provider<AuditTrailRepository>((ref) {
  return AuditTrailRepository(ref.read(apiClientProvider));
});

// ── Dealers ──────────────────────────────────────────────────────────────────
final dealerRepositoryProvider = Provider<DealerRepository>((ref) {
  return DealerRepository(ref.read(apiClientProvider));
});

// ── Finance ──────────────────────────────────────────────────────────────────
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.read(apiClientProvider));
});

// ── Logistics ────────────────────────────────────────────────────────────────
final logisticsRepositoryProvider = Provider<LogisticsRepository>((ref) {
  return LogisticsRepository(ref.read(apiClientProvider));
});

// ── BESS ─────────────────────────────────────────────────────────────────────
final bessRepositoryProvider = Provider<BessRepository>((ref) {
  return BessRepository(ref.read(apiClientProvider));
});

// ── Fleet Ops ────────────────────────────────────────────────────────────────
final fleetOpsRepositoryProvider = Provider<FleetOpsRepository>((ref) {
  return FleetOpsRepository(ref.read(apiClientProvider));
});

// ── Notifications ────────────────────────────────────────────────────────────
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiClientProvider));
});

// ── Support ──────────────────────────────────────────────────────────────────
final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.read(apiClientProvider));
});

// ── Audit & Security ─────────────────────────────────────────────────────────
final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.read(apiClientProvider));
});

// ── Settings ─────────────────────────────────────────────────────────────────
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(apiClientProvider));
});

// ── Users ────────────────────────────────────────────────────────────────────
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return RoleRepository();
});

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return KycRepository(ref.read(apiClientProvider));
});


final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(ref.read(apiClientProvider));
});

final userAnalyticsRepositoryProvider =
    Provider<user_analytics.AnalyticsRepository>((ref) {
  return user_analytics.AnalyticsRepository(ref.read(apiClientProvider));
});

// ── Battery Health ───────────────────────────────────────────────────────────
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(ref.read(apiClientProvider));
});
