import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_size/window_size.dart';

import 'app_theme.dart';
import 'main_shell.dart';

final ThemeController themeController = ThemeController();
final TextScaleController textScaleController = TextScaleController();

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
    // setWindowMaxSize(size); // optional: lock size
  }

  runApp(
    ThemeScope(
      controller: themeController,
      child: TextScaleScope(
        controller: textScaleController,
        child: const MasjidApp(),
      ),
    ),
  );
}

class MasjidApp extends StatelessWidget {
  const MasjidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final textScale = TextScaleScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([theme, textScale]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Masjid Raudlatus Sholihin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.mode,
          home: const MainShell(),

          // ✅ Apply font scaling globally
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                // Flutter 3.16+ (recommended)
                textScaler: TextScaler.linear(textScale.scale),
                // If your Flutter is old and this errors, tell me—I'll give the old API version.
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}