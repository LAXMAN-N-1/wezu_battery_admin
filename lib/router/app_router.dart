import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/session_expired_overlay.dart';
import '../features/auth/provider/auth_provider.dart';
import '../features/auth/view/login_view.dart';
import '../features/dashboard/view/dashboard_view.dart';
import '../features/bess/view/bess_overview_view.dart';
import '../features/bess/view/energy_monitoring_view.dart';
import '../features/bess/view/grid_integration_view.dart';
import '../features/bess/view/bess_reports_view.dart';
import '../features/notifications/view/send_push_view.dart';
import '../features/notifications/view/automated_triggers_view.dart';
import '../features/notifications/view/notification_logs_view.dart';
import '../features/notifications/view/sms_email_config_view.dart';
import '../features/cms/view/blog_management_view.dart';
import '../features/cms/view/faq_management_view.dart';
import '../features/cms/view/banner_management_view.dart';
import '../features/cms/view/legal_docs_view.dart';
import '../features/cms/view/media_library_view.dart';
import '../features/audit/view/audit_dashboard_view.dart';
import '../features/audit/view/audit_logs_view.dart';
import '../features/audit/view/security_events_view.dart';
import '../features/audit/view/security_settings_view.dart';
import '../features/settings/view/general_settings_view.dart';
import '../features/settings/view/feature_flags_view.dart';
import '../features/settings/view/api_keys_view.dart';
import '../features/settings/view/system_health_view.dart';
import '../features/inventory/view/stock_levels_view.dart';
import '../features/inventory/view/bulk_import_export_view.dart';
import '../features/inventory/view/audit_trail_view.dart';
import '../features/battery_health/view/battery_health_view.dart';
import '../features/stations/view/stations_view.dart';
import '../features/users/view/fraud_risk_view.dart';
import '../features/finance/view/finance_view.dart';
import '../features/finance/view/transactions_view.dart';
import '../features/finance/view/settlements_view.dart';
import '../features/finance/view/invoices_view.dart';
import '../features/finance/view/profit_analysis_view.dart';
import '../features/logistics/view/delivery_orders_view.dart';
import '../features/logistics/view/live_tracking_view.dart';
import '../features/logistics/view/drivers_view.dart';
import '../features/logistics/view/route_planner_view.dart';
import '../features/logistics/view/returns_view.dart';
import '../features/inventory/view/batteries_view.dart';
import '../features/support/view/support_view.dart';
import '../features/support/view/knowledge_base_view.dart';
import '../features/support/view/team_performance_view.dart';
import '../features/dashboard/view/analytics_view.dart';
import '../features/stations/view/station_map_view.dart';
import '../features/stations/view/station_performance_view.dart';
import '../features/stations/view/station_maintenance_view.dart';
import '../features/dealers/view/dealers_view.dart';
import '../features/dealers/view/dealer_onboarding_view.dart';
import '../features/dealers/view/dealer_kyc_view.dart';
import '../features/dealers/view/dealer_commissions_view.dart';
import '../features/dealers/view/dealer_documents_view.dart';
import '../features/locations/view/location_view.dart';
import '../features/rentals/view/active_rentals_view.dart';
import '../features/rentals/view/rental_history_view.dart';
import '../features/rentals/view/battery_swaps_view.dart';
import '../features/rentals/view/purchase_orders_view.dart';
import '../features/rentals/view/late_fees_view.dart';
import '../features/fleet_ops/view/iot_dashboard_view.dart';
import '../features/fleet_ops/view/geofencing_view.dart';
import '../features/fleet_ops/view/telematics_view.dart';
import '../features/fleet_ops/view/alerts_alarms_view.dart';
import '../features/user_master/view/users_master_list_view.dart';
import '../features/user_master/view/dev_user_create_view.dart';
import '../features/user_master/view/user_master_form_view.dart';
import '../features/user_master/view/roles_permissions_master_view.dart';
import '../features/user_master/view/admin_groups_master_view.dart';
import '../features/user_master/view/access_logs_master_view.dart';
import '../features/user_master/view/user_bulk_master_view.dart';
import '../core/widgets/admin_layout.dart';

final _routerRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (_, __) {
    notifier.value++;
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(_routerRefreshProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggingIn = state.matchedLocation == '/login';

      if (authState.isLoading) {
        return isLoggingIn ? null : '/login';
      }

      if (!authState.isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      if (authState.isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      ShellRoute(
        builder: (context, state, child) {
          return AdminLayout(
            title: _getTitle(state.matchedLocation),
            child: child,
          );
        },
        routes: [
          // ==========================================
          // 1. DASHBOARD
          // ==========================================
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardView()),
            routes: [
              GoRoute(
                path: 'analytics',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AnalyticsView()),
              ),
            ],
          ),

          // ==========================================
          // 2. USER MASTER
          // ==========================================
          GoRoute(
            path: '/user-master',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UsersMasterListView()),
            routes: [
              GoRoute(
                path: 'create',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DevUserCreateView()),
              ),
              GoRoute(
                path: 'edit',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: UserMasterFormView()),
              ),
              GoRoute(
                path: 'roles',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: RolesPermissionsMasterView()),
              ),
              GoRoute(
                path: 'groups',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AdminGroupsMasterView()),
              ),
              GoRoute(
                path: 'logs',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AccessLogsMasterView()),
              ),
              GoRoute(
                path: 'bulk',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: UserBulkMasterView()),
              ),
            ],
          ),

          GoRoute(
            path: '/locations',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LocationView()),
          ),

          // ==========================================
          // 3. FLEET & INVENTORY
          // ==========================================
          GoRoute(
            path: '/fleet/batteries',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BatteriesView()),
          ),
          GoRoute(
            path: '/fleet/stock',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StockLevelsView()),
          ),
          GoRoute(
            path: '/fleet/health',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BatteryHealthView()),
          ),
          GoRoute(
            path: '/fleet/audit',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AuditTrailView()),
          ),
          GoRoute(
            path: '/fleet/bulk',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BulkImportExportView()),
          ),

          // ==========================================
          // 4. STATIONS
          // ==========================================
          GoRoute(
            path: '/stations',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StationsView()),
            routes: [
              GoRoute(
                path: 'map',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: StationMapView()),
              ),
              GoRoute(
                path: 'performance',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: StationPerformanceView()),
              ),
              GoRoute(
                path: 'maintenance',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: StationMaintenanceView()),
              ),
            ],
          ),

          // ==========================================
          // 5. DEALERS
          // ==========================================
          GoRoute(
            path: '/dealers',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DealersView()),
            routes: [
              GoRoute(
                path: 'registrations',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DealerOnboardingView()),
              ),
              GoRoute(
                path: 'kyc',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DealerKycView()),
              ),
              GoRoute(
                path: 'commissions',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DealerCommissionsView()),
              ),
              GoRoute(
                path: 'documents',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DealerDocumentsView()),
              ),
            ],
          ),

          // ==========================================
          // 6. RENTALS & ORDERS
          // ==========================================
          GoRoute(
            path: '/rentals/active',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ActiveRentalsView()),
          ),
          GoRoute(
            path: '/rentals/history',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RentalHistoryView()),
          ),
          GoRoute(
            path: '/rentals/swaps',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BatterySwapsView()),
          ),
          GoRoute(
            path: '/rentals/purchases',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PurchaseOrdersView()),
          ),
          GoRoute(
            path: '/rentals/late-fees',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LateFeesView()),
          ),

          // ==========================================
          // 7. FINANCE
          // ==========================================
          GoRoute(
            path: '/finance',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FinanceView()),
            routes: [
              GoRoute(
                path: 'transactions',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TransactionsView()),
              ),
              GoRoute(
                path: 'settlements',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SettlementsView()),
              ),
              GoRoute(
                path: 'invoices',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: InvoicesView()),
              ),
              GoRoute(
                path: 'profit',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfitAnalysisView()),
              ),
            ],
          ),

          // ==========================================
          // 8. LOGISTICS
          // ==========================================
          GoRoute(
            path: '/logistics/orders',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DeliveryOrdersView()),
          ),
          GoRoute(
            path: '/logistics/tracking',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LiveTrackingView()),
          ),
          GoRoute(
            path: '/logistics/drivers',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DriversView()),
          ),
          GoRoute(
            path: '/logistics/routes',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RoutePlannerView()),
          ),
          GoRoute(
            path: '/logistics/returns',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReturnsView()),
          ),

          // ==========================================
          // 9. FLEET OPERATIONS
          // ==========================================
          GoRoute(
            path: '/fleet-ops/iot',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: IoTDashboardView()),
          ),
          GoRoute(
            path: '/fleet-ops/geofence',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GeofencingView()),
          ),
          GoRoute(
            path: '/fleet-ops/telematics',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TelematicsView()),
          ),
          GoRoute(
            path: '/fleet-ops/alerts',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AlertsAlarmsView()),
          ),

          // ==========================================
          // 10. BESS
          // ==========================================
          GoRoute(
            path: '/bess',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BessOverviewView()),
            routes: [
              GoRoute(
                path: 'monitoring',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: EnergyMonitoringView()),
              ),
              GoRoute(
                path: 'grid',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: GridIntegrationView()),
              ),
              GoRoute(
                path: 'reports',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BessReportsView()),
              ),
            ],
          ),

          // ==========================================
          // 11. SUPPORT
          // ==========================================
          GoRoute(
            path: '/support/tickets',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SupportView()),
          ),
          GoRoute(
            path: '/support/knowledge',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: KnowledgeBaseView()),
          ),
          GoRoute(
            path: '/support/performance',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TeamPerformanceView()),
          ),

          // ==========================================
          // 11. NOTIFICATIONS
          // ==========================================
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SendPushView()),
            routes: [
              GoRoute(
                path: 'send',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SendPushView()),
              ),
              GoRoute(
                path: 'triggers',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AutomatedTriggersView()),
              ),
              GoRoute(
                path: 'logs',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: NotificationLogsView()),
              ),
              GoRoute(
                path: 'config',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SmsEmailConfigView()),
              ),
            ],
          ),

          // ==========================================
          // 12. CMS
          // ==========================================
          GoRoute(
            path: '/cms',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BlogManagementView()),
            routes: [
              GoRoute(
                path: 'blogs',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BlogManagementView()),
              ),
              GoRoute(
                path: 'faqs',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: FaqManagementView()),
              ),
              GoRoute(
                path: 'banners',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BannerManagementView()),
              ),
              GoRoute(
                path: 'legal',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: LegalDocsView()),
              ),
              GoRoute(
                path: 'media',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MediaLibraryView()),
              ),
            ],
          ),

          // ==========================================
          // 13. AUDIT & SECURITY
          // ==========================================
          GoRoute(
            path: '/audit/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AuditDashboardView()),
          ),
          GoRoute(
            path: '/audit/logs',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AuditLogsView()),
          ),
          GoRoute(
            path: '/audit/fraud',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FraudRiskView()),
          ),
          GoRoute(
            path: '/audit/security-events',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SecurityEventsView()),
          ),
          GoRoute(
            path: '/audit/security',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SecuritySettingsView()),
          ),

          // ==========================================
          // 14. SETTINGS
          // ==========================================
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GeneralSettingsView()),
            routes: [
              GoRoute(
                path: 'features',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: FeatureFlagsView()),
              ),
              GoRoute(
                path: 'api-keys',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ApiKeysView()),
              ),
              GoRoute(
                path: 'health',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SystemHealthView()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

String _getTitle(String location) {
  // Dashboard
  if (location == '/dashboard') return 'Dashboard Overview';
  if (location == '/dashboard/analytics') return 'Platform Analytics';

  // User Master
  if (location == '/user-master') return 'All Users';
  if (location == '/user-master/create') return 'Create User';
  if (location == '/user-master/edit') return 'Add / Edit User';
  if (location == '/user-master/roles') return 'Roles & Permissions';
  if (location == '/user-master/groups') return 'Admin Groups';
  if (location == '/user-master/logs') return 'Access Logs';
  if (location == '/user-master/bulk') return 'Bulk Import/Export';

  // Fleet
  if (location == '/fleet/batteries') return 'All Batteries';
  if (location == '/fleet/stock') return 'Stock Levels';
  if (location == '/fleet/health') return 'Battery Health';
  if (location == '/fleet/audit') return 'Inventory Audit Trail';
  if (location == '/fleet/bulk') return 'Bulk Import / Export';

  // Stations
  if (location == '/stations') return 'All Stations';
  if (location == '/stations/map') return 'Station Map';
  if (location == '/stations/performance') return 'Station Performance';
  if (location == '/stations/maintenance') return 'Maintenance Schedules';

  // Dealers
  if (location == '/dealers') return 'All Dealers';
  if (location == '/dealers/registrations') return 'Registration Requests';
  if (location == '/dealers/kyc') return 'Dealer KYC & Verification';
  if (location == '/dealers/commissions') return 'Commissions';
  if (location == '/dealers/documents') return 'Dealer Documents';

  // Rentals
  if (location == '/rentals/active') return 'Active Rentals';
  if (location == '/rentals/history') return 'Rental History';
  if (location == '/rentals/swaps') return 'Battery Swaps';
  if (location == '/rentals/purchases') return 'Purchase Orders';
  if (location == '/rentals/late-fees') return 'Late Fees';

  // Finance
  if (location == '/finance') return 'Revenue Dashboard';
  if (location == '/finance/transactions') return 'Transactions';
  if (location == '/finance/settlements') return 'Settlements';
  if (location == '/finance/invoices') return 'Invoices';
  if (location == '/finance/profit') return 'Profit Analysis';

  // Logistics
  if (location == '/logistics/orders') return 'Delivery Orders';
  if (location == '/logistics/tracking') return 'Live Tracking';
  if (location == '/logistics/drivers') return 'Drivers';
  if (location == '/logistics/routes') return 'Route Planner';
  if (location == '/logistics/returns') return 'Returns';

  // Fleet Ops
  if (location == '/fleet-ops/iot') return 'IoT Dashboard';
  if (location == '/fleet-ops/geofence') return 'Geofencing';
  if (location == '/fleet-ops/telematics') return 'Telematics';
  if (location == '/fleet-ops/alerts') return 'Alerts & Alarms';

  // BESS
  if (location == '/bess') return 'BESS Overview';
  if (location == '/bess/monitoring') return 'Energy Monitoring';
  if (location == '/bess/grid') return 'Grid Integration';
  if (location == '/bess/reports') return 'BESS Reports';

  // Support
  if (location == '/support/tickets') return 'Support Tickets';
  if (location == '/support/knowledge') return 'Knowledge Base';
  if (location == '/support/performance') return 'Team Performance';

  // Notifications
  if (location == '/notifications/send') return 'Send Push';
  if (location == '/notifications/triggers') return 'Automated Triggers';
  if (location == '/notifications/logs') return 'Notification Logs';
  if (location == '/notifications/config') return 'SMS/Email Config';

  // CMS
  if (location == '/cms/blogs') return 'Blog Management';
  if (location == '/cms/faqs') return 'FAQ Management';
  if (location == '/cms/banners') return 'Banner Management';
  if (location == '/cms/legal') return 'Legal Documents';

  // Audit
  if (location == '/audit/dashboard') return 'Audit & Security Dashboard';
  if (location == '/audit/logs') return 'System Audit Logs';
  if (location == '/audit/security-events') return 'Security Events';
  if (location == '/audit/security') return 'Security Settings';

  // Settings
  if (location == '/settings') return 'General Settings';
  if (location == '/settings/features') return 'Feature Flags';
  if (location == '/settings/api-keys') return 'API Keys';
  if (location == '/settings/health') return 'System Health';

  return 'Admin Portal';
}
