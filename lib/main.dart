import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load user settings from local storage
  final settings = SettingsService();
  await settings.load();

  // Initialize local notifications
  await NotificationService.instance.init();

  // Re-initialize Supabase and sync if user was previously signed in
  if (await SettingsService.wasSupabasePreviouslyInitialized()) {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
      );
      await SettingsService.markSupabaseReady();
      // Sync settings on app start (polling strategy)
      await settings.syncFromSupabase();
    } catch (e) {
      debugPrint('Supabase re-init on start failed: $e');
    }
  }

  runApp(MoTimerApp(settings: settings));
}

class MoTimerApp extends StatefulWidget {
  final SettingsService settings;

  const MoTimerApp({super.key, required this.settings});

  @override
  State<MoTimerApp> createState() => _MoTimerAppState();
}

class _MoTimerAppState extends State<MoTimerApp> {
  @override
  void initState() {
    super.initState();
    // Rebuild when theme color changes
    widget.settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seedColor = widget.settings.themeOption.color;

    return MaterialApp(
      title: 'MoTimer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(settings: widget.settings),
    );
  }
}
