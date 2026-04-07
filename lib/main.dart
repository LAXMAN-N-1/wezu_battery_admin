import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/app_scaffold_keys.dart';
import 'core/widgets/session_expired_overlay.dart';
import 'features/auth/provider/auth_provider.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    // Register the session-expired callback so the ApiClient can trigger the
    // modal overlay when a 401 is detected (instead of just changing auth
    // state silently).
    final apiClient = ApiClient();
    apiClient.registerSessionExpiredCallback(() async {
      _showSessionExpiredModal();
    });
  }

  void _showSessionExpiredModal() {
    SessionExpiredOverlay.show(
      onLogin: () {
        // Clear auth state → GoRouter redirect sends user to /login.
        final notifier = ref.read(authProvider.notifier);
        notifier.clearSessionAndRedirect();
        // Unlock the ApiClient so the next login attempt can work.
        ApiClient().unlockSession();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'PowerFill Admin',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
