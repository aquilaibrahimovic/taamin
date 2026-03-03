import 'dart:io' show Platform; // Only Platform is needed now
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_size/window_size.dart';
import 'services/notification_service.dart';
import 'app_theme.dart';
import 'main_shell.dart';
import 'settings.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

// Late initialization for global access to the settings controller
late final SettingsController settingsController;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Simplified .env loading as an asset
  // IMPORTANT: You must add the .env file to the 'assets' section of pubspec.yaml
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Could not load .env from assets. Ensure it is listed in pubspec.yaml.");
  }

  // Initialize Firebase once
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.instance.init();

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

  // Load stored settings before runApp
  final prefs = await SharedPreferences.getInstance();
  final service = SettingsService(prefs);
  settingsController = SettingsController(service);

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

          // ✅ Apply font scaling globally based on user settings
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(settings.textScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('id'),
          ],
        );
      },
    );
  }
}