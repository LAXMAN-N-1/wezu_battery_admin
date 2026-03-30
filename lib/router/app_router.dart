import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/provider/auth_provider.dart';
import '../features/auth/view/login_view.dart';
import '../features/dashboard/view/dashboard_view.dart';
import '../features/cms/view/blog_list_view.dart';
import '../features/cms/view/faq_list_view.dart';
import '../features/cms/view/legal_list_view.dart';
import '../features/cms/view/banner_list_view.dart';
import '../features/cms/view/media_library_view.dart';
import '../features/inventory/view/stock_levels_view.dart';
import '../features/inventory/view/bulk_import_export_view.dart';
import '../features/battery_health/view/battery_health_view.dart';
import '../features/stations/view/stations_view.dart';
import '../features/users/view/users_view.dart';
import '../features/users/view/roles_permissions_view.dart';
import '../features/users/view/kyc_verification_view.dart';
import '../features/users/view/kyc_dashboard_view.dart';
import '../features/users/view/suspended_accounts_view.dart';
import '../features/users/view/user_analytics_view.dart';
import '../features/users/view/fraud_risk_view.dart';
import '../features/users/view/bulk_operations_view.dart';
import '../features/users/view/session_activity_view.dart';
import '../features/finance/view/finance_view.dart';
import '../features/inventory/view/batteries_view.dart';
import '../features/support/view/support_view.dart';
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
import '../features/user_master/view/user_master_form_view.dart';
import '../features/user_master/view/roles_permissions_master_view.dart';
import '../features/user_master/view/admin_groups_master_view.dart';
import '../features/user_master/view/access_logs_master_view.dart';
import '../features/user_master/view/user_bulk_master_view.dart';
import '../core/widgets/admin_layout.dart';
import '../core/widgets/placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      
      if (!authState.isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      
      if (authState.isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
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
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardView()),
            routes: [
              GoRoute(
                path: 'analytics',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AnalyticsView(),
                ),
              ),
            ],
          ),

          // ==========================================
          // 2. USER MASTER
          // ==========================================
          GoRoute(
            path: '/user-master',
            pageBuilder: (context, state) => const NoTransitionPage(child: UsersMasterListView()),
            routes: [
              GoRoute(
                path: 'edit',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: UserMasterFormView(),
                ),
              ),
              GoRoute(
                path: 'roles',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: RolesPermissionsMasterView(),
                ),
              ),
              GoRoute(
                path: 'groups',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AdminGroupsMasterView(),
                ),
              ),
              GoRoute(
                path: 'logs',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AccessLogsMasterView(),
                ),
              ),
              GoRoute(
                path: 'bulk',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: UserBulkMasterView(),
                ),
              ),
            ],
          ),
          
          GoRoute(
            path: '/locations',
            pageBuilder: (context, state) => const NoTransitionPage(child: LocationView()),
          ),

          // ==========================================
          // 3. FLEET & INVENTORY
          // ==========================================
          GoRoute(
            path: '/fleet/batteries',
            pageBuilder: (context, state) => const NoTransitionPage(child: BatteriesView()),
          ),
          GoRoute(
            path: '/fleet/stock',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StockLevelsView(),
            ),
          ),
          GoRoute(
            path: '/fleet/health',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BatteryHealthView(),
            ),
          ),
          GoRoute(
            path: '/fleet/audit',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Inventory Audit Trail', icon: Icons.history_outlined, description: 'Track all inventory changes — who changed what, when, and why.'),
            ),
          ),
          GoRoute(
            path: '/fleet/bulk',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BulkImportExportView(),
            ),
          ),

          // ==========================================
          // 4. STATIONS
          // ==========================================
          GoRoute(
            path: '/stations',
            pageBuilder: (context, state) => const NoTransitionPage(child: StationsView()),
            routes: [
              GoRoute(
                path: 'map',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: StationMapView(),
                ),
              ),
              GoRoute(
                path: 'performance',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: StationPerformanceView(),
                ),
              ),
              GoRoute(
                path: 'maintenance',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: StationMaintenanceView(),
                ),
              ),
            ],
          ),

          // ==========================================
          // 5. DEALERS
          // ==========================================
          GoRoute(
            path: '/dealers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DealersView(),
            ),
            routes: [
              GoRoute(
                path: 'registrations',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DealerOnboardingView(),
                ),
              ),
              GoRoute(
                path: 'kyc',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DealerKycView(),
                ),
              ),
              GoRoute(
                path: 'commissions',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DealerCommissionsView(),
                ),
              ),
              GoRoute(
                path: 'documents',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DealerDocumentsView(),
                ),
              ),
            ],
          ),

          // ==========================================
          // 6. RENTALS & ORDERS
          // ==========================================
          GoRoute(
            path: '/rentals/active',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ActiveRentalsView(),
            ),
          ),
          GoRoute(
            path: '/rentals/history',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RentalHistoryView(),
            ),
          ),
          GoRoute(
            path: '/rentals/swaps',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BatterySwapsView(),
            ),
          ),
          GoRoute(
            path: '/rentals/purchases',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PurchaseOrdersView(),
            ),
          ),
          GoRoute(
            path: '/rentals/late-fees',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LateFeesView(),
            ),
          ),

          // ==========================================
          // 7. FINANCE
          // ==========================================
          GoRoute(
            path: '/finance',
            pageBuilder: (context, state) => const NoTransitionPage(child: FinanceView()),
            routes: [
              GoRoute(
                path: 'transactions',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'Transactions', icon: Icons.receipt_outlined, description: 'All payment transactions with search, filters, refund status, and export.'),
                ),
              ),
              GoRoute(
                path: 'settlements',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'Settlements', icon: Icons.account_balance_wallet_outlined, description: 'Dealer payment settlements, schedule tracking, and reconciliation.'),
                ),
              ),
              GoRoute(
                path: 'invoices',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'Invoices', icon: Icons.description_outlined, description: 'Auto-generated invoices with GST, downloadable PDFs, and email delivery.'),
                ),
              ),
              GoRoute(
                path: 'profit',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'Profit Analysis', icon: Icons.trending_up_outlined, description: 'Profit margins per station, cost vs revenue trends, and profitability forecast.'),
                ),
              ),
            ],
          ),

          // ==========================================
          // 8. LOGISTICS
          // ==========================================
          GoRoute(
            path: '/logistics/orders',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Delivery Orders', icon: Icons.local_shipping_outlined, description: 'Create and manage delivery orders. Track status from pending to delivered.'),
            ),
          ),
          GoRoute(
            path: '/logistics/tracking',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Live Tracking', icon: Icons.gps_fixed_outlined, description: 'Real-time GPS map with delivery vehicles, ETA calculations, and delay alerts.'),
            ),
          ),
          GoRoute(
            path: '/logistics/drivers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Drivers', icon: Icons.badge_outlined, description: 'Driver profiles, availability status, performance metrics, and ratings.'),
            ),
          ),
          GoRoute(
            path: '/logistics/routes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Route Planner', icon: Icons.route_outlined, description: 'Optimized route calculation, multi-stop planning, and traffic consideration.'),
            ),
          ),
          GoRoute(
            path: '/logistics/returns',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Returns', icon: Icons.assignment_return_outlined, description: 'Reverse logistics — return initiations, pickup scheduling, and processing.'),
            ),
          ),

          // ==========================================
          // 9. FLEET OPERATIONS
          // ==========================================
          GoRoute(
            path: '/fleet-ops/iot',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: IoTDashboardView(),
            ),
          ),
          GoRoute(
            path: '/fleet-ops/geofence',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GeofencingView(),
            ),
          ),
          GoRoute(
            path: '/fleet-ops/telematics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TelematicsView(),
            ),
          ),
          GoRoute(
            path: '/fleet-ops/alerts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AlertsAlarmsView(),
            ),
          ),

          // ==========================================
          // 10. BESS
          // ==========================================
          GoRoute(
            path: '/bess',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'BESS Overview', icon: Icons.bolt_outlined, description: 'Battery Energy Storage System status, capacity, and utilization overview.'),
            ),
            routes: [
              GoRoute(
                path: 'monitoring',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'Energy Monitoring', icon: Icons.electric_meter_outlined, description: 'Real-time charge/discharge monitoring, power flow visualization.'),
                ),
              ),
              GoRoute(
                path: 'grid',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'Grid Integration', icon: Icons.grid_on_outlined, description: 'Grid connection status, peak shaving schedules, and power management.'),
                ),
              ),
              GoRoute(
                path: 'reports',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'BESS Reports', icon: Icons.summarize_outlined, description: 'Energy stored/discharged reports, efficiency metrics, and ROI analysis.'),
                ),
              ),
            ],
          ),

          // ==========================================
          // 11. SUPPORT
          // ==========================================
          GoRoute(
            path: '/support/tickets',
            pageBuilder: (context, state) => const NoTransitionPage(child: SupportView()),
          ),
          GoRoute(
            path: '/support/knowledge',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Knowledge Base', icon: Icons.menu_book_outlined, description: 'FAQ articles, categorized guides, and self-service knowledge management.'),
            ),
          ),
          GoRoute(
            path: '/support/performance',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Team Performance', icon: Icons.leaderboard_outlined, description: 'Agent resolution times, CSAT scores, ticket volumes, and quality metrics.'),
            ),
          ),

          // ==========================================
          // 11. NOTIFICATIONS
          // ==========================================
          GoRoute(
            path: '/notifications',
            redirect: (_, __) => '/notifications/send',
            routes: [
              GoRoute(
                path: 'send',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'Send Push Notifications', icon: Icons.send_outlined, description: 'Target specific user segments, schedule campaigns, and track open rates.'),
                ),
              ),
              GoRoute(
                path: 'triggers',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'Automated Triggers', icon: Icons.auto_awesome_outlined, description: 'Configure behavioral triggers for push/SMS (e.g., in-activity, rental reminders).'),
                ),
              ),
              GoRoute(
                path: 'logs',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'Notification Logs', icon: Icons.history_edu_outlined, description: 'Audit trail of every notification sent to users with delivery status.'),
                ),
              ),
              GoRoute(
                path: 'config',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'SMS & Email Config', icon: Icons.settings_suggest_outlined, description: 'Link Twilio, SendGrid, or Firebase credentials for external alerts.'),
                ),
              ),
            ],
          ),

          // ==========================================
          // 12. CMS
          // ==========================================
          GoRoute(
            path: '/cms',
            redirect: (_, __) => '/cms/blogs',
            routes: [
              GoRoute(
                path: 'blogs',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BlogListView(),
                ),
              ),
              GoRoute(
                path: 'faqs',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FaqListView(),
                ),
              ),
              GoRoute(
                path: 'banners',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BannerListView(),
                ),
              ),
              GoRoute(
                path: 'legal',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: LegalListView(),
                ),
              ),
              GoRoute(
                path: 'media',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MediaLibraryView(),
                ),
              ),
            ],
          ),

          // ==========================================
          // 13. AUDIT & SECURITY
          // ==========================================
          GoRoute(
            path: '/audit/logs',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Audit Logs', icon: Icons.manage_search_outlined, description: 'Complete audit trail of all admin actions — who, what, when.'),
            ),
          ),
          GoRoute(
            path: '/audit/fraud',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FraudRiskView(),
            ),
          ),
          GoRoute(
            path: '/audit/security',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Security Settings', icon: Icons.lock_outlined, description: 'Two-factor authentication, session management, and IP whitelisting.'),
            ),
          ),

          // ==========================================
          // 14. SETTINGS
          // ==========================================
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'General Settings', icon: Icons.settings_outlined, description: 'Platform name, logo, timezone, currency, and branding configuration.'),
            ),
            routes: [
              GoRoute(
                path: 'api-keys',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'API Keys', icon: Icons.vpn_key_outlined, description: 'Configure Razorpay, Google Maps, Twilio, Firebase, and other integrations.'),
                ),
              ),
              GoRoute(
                path: 'health',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlaceholderScreen(title: 'System Health', icon: Icons.monitor_heart_outlined, description: 'Server status, database connectivity, Redis, MQTT, and service health checks.'),
                ),
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

  // CMS
  if (location == '/cms/notifications') return 'Push Notifications';
  if (location == '/cms/promotions') return 'Promotions';
  if (location == '/cms/faqs') return 'FAQ Management';

  // Audit
  if (location == '/audit/logs') return 'Audit Logs';
  if (location == '/audit/fraud') return 'Fraud Detection';
  if (location == '/audit/security') return 'Security Settings';

  // Settings
  if (location == '/settings') return 'General Settings';
  if (location == '/settings/api-keys') return 'API Keys';
  if (location == '/settings/health') return 'System Health';

  return 'Admin Portal';
}
