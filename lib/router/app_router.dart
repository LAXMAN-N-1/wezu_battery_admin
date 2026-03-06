import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/view/login_view.dart';
import '../features/auth/provider/auth_provider.dart';
import '../features/dashboard/view/dashboard_view.dart';
import '../features/inventory/view/batteries_view.dart';
import '../features/stations/view/stations_view.dart';
import '../features/stations/view/station_monitor_view.dart';
import '../features/users/view/users_view.dart';
import '../features/finance/view/finance_view.dart';
import '../features/support/view/support_view.dart';
import '../core/widgets/admin_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';

      // Still loading authentication state
      if (authState.isLoading) {
         // Stay on login page or redirect to login while loading to prevent flashing the dashboard
         return isLoggingIn ? null : '/login';
      }

      // Not authenticated
      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // Authenticated but trying to access login page
      if (isLoggingIn) {
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
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardView()),
          ),
          GoRoute(
            path: '/inventory',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: Center(child: Text('Inventory Module')),
            ),
            routes: [
              GoRoute(
                path: 'batteries',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BatteriesView()),
              ),
              GoRoute(
                path: 'stock-levels',
                builder: (context, state) =>
                    const Center(child: Text('Stock Levels')),
              ),
            ],
          ),
          GoRoute(
            path: '/stations',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StationsView()),
            routes: [
              GoRoute(
                path: 'monitor',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: StationMonitorView()),
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UsersView()),
          ),
          GoRoute(
            path: '/finance',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FinanceView()),
          ),
          GoRoute(
            path: '/support',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SupportView()),
          ),
        ],
      ),
    ],
  );
});

String _getTitle(String location) {
  if (location.startsWith('/dashboard')) return 'Dashboard Overview';
  if (location.startsWith('/inventory')) return 'Fleet & Inventory';
  if (location.startsWith('/stations/monitor')) return 'Station Monitor';
  if (location.startsWith('/stations')) return 'Station Management';
  if (location.startsWith('/users')) return 'User Management';
  if (location.startsWith('/finance')) return 'Financial Reports';
  if (location.startsWith('/support')) return 'Support Center';
  return 'Admin Portal';
}
