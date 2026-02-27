import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_size/window_size.dart';

import 'app_theme.dart';
import 'main_shell.dart';

final ThemeController themeController = ThemeController();

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
      child: const MasjidApp(),
    ),
  );
}

class MasjidApp extends StatelessWidget {
  const MasjidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Masjid Raudlatus Sholihin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: controller.mode, // ✅ system by default, user can override
          home: const MainShell(),
        );
      },
    );
  }
}