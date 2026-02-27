import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_size/window_size.dart';
import 'app_theme.dart';
import 'main_shell.dart';
import 'settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

late final SettingsController settingsController;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait on mobile only
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  // Portrait-like window on desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    setWindowTitle('Masjid Raudlatus Sholihin');
    const size = Size(420, 800);
    setWindowFrame(Rect.fromLTWH(100, 100, size.width, size.height));
    setWindowMinSize(size);
  }

  // ✅ Load stored settings before runApp
  final prefs = await SharedPreferences.getInstance();
  final service = SettingsService(prefs);
  settingsController = SettingsController(service);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('id_ID', null);

  runApp(
    SettingsScope(
      controller: settingsController,
      child: const MasjidApp(),
    ),
  );
}

class MasjidApp extends StatelessWidget {
  const MasjidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Masjid Raudlatus Sholihin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          home: const MainShell(),

          // ✅ Apply font scaling globally
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(settings.textScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}