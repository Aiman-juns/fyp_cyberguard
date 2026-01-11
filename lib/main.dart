import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'config/router_config.dart' as app_router;
import 'shared/theme/app_theme.dart';
import 'shared/providers/theme_provider.dart';
import 'core/services/migration_service.dart';
import 'core/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  // Make sure .env file exists in project root with: GG_AI_KEY=your_api_key
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase before running the app
  await SupabaseConfig.initialize();

  // Run one-time migration from SharedPreferences to Supabase
  // This will automatically migrate existing progress data if needed
  await MigrationService.migrate();

  // Initialize local notifications
  await LocalNotificationService.initialize();
  await LocalNotificationService.requestPermissions();
  
  // Schedule daily challenge notification (9 AM)
  await LocalNotificationService.scheduleDailyChallenge(hour: 9);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App is going to background or being closed
      debugPrint('📱 APP LIFECYCLE: Going to background, scheduling comeback reminder');
      LocalNotificationService.scheduleComebackReminder();
    } else if (state == AppLifecycleState.resumed) {
      // App is coming back to foreground
      debugPrint('📱 APP LIFECYCLE: App resumed, canceling comeback reminder');
      LocalNotificationService.cancelComebackReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'CyberGuard',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routerConfig: app_router.RouterConfig.router,
    );
  }
}
