import 'dart:io' show Platform, Directory, File, FileSystemException; // Combined here
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_size/window_size.dart';
import 'app_theme.dart';
import 'main_shell.dart';
import 'settings.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

// NEW: for joining paths safely across OSes
import 'package:path/path.dart' as p;

late final SettingsController settingsController;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load local env vars (DO NOT commit .env)
  // On Windows desktop, the working directory can be build\windows\...\Debug,
  // so we try:
  // 1) project working directory + .env
  // 2) next to the executable + .env
  final candidates = <String>[
    p.join(Directory.current.path, '.env'),
    if (!kIsWeb) p.join(File(Platform.resolvedExecutable).parent.path, '.env'),
  ];

  String? envPath;
  for (final c in candidates) {
    if (File(c).existsSync()) {
      envPath = c;
      break;
    }
  }

  if (envPath == null) {
    throw FileSystemException(
      'Could not find .env. Put it in the project root, or copy it next to the exe '
          '(e.g. build/windows/x64/runner/Debug/.env).',
    );
  }

  await dotenv.load(fileName: envPath);

  // Initialize Firebase once
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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