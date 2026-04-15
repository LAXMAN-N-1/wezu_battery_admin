import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/app_scaffold_keys.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Environment Variables (graceful fail)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ Dotenv loaded successfully");
  } catch (e) {
    debugPrint("⚠️ Dotenv load failed: $e");
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
