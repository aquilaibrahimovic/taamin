import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  // Light/Dark shared structure
  final Color bgColor1;
  final Color bgColor2;
  final Color bgColor3;

  final Color textColor1;
  final Color textColor2;

  final Color accent1a;
  final Color accent1b;
  final Color accent2a;
  final Color accent2b;

  final Color yesColor;
  final Color noColor;

  const AppThemeColors({
    required this.bgColor1,
    required this.bgColor2,
    required this.bgColor3,
    required this.textColor1,
    required this.textColor2,
    required this.accent1a,
    required this.accent1b,
    required this.accent2a,
    required this.accent2b,
    required this.yesColor,
    required this.noColor,
  });

  static const light = AppThemeColors(
    bgColor1: Color(0xFFF8FAFC),
    bgColor2: Color(0xFFF1F5F9),
    bgColor3: Color(0xFFE2E8F0),
    textColor1: Color(0xFF020617),
    textColor2: Color(0xFF475569),
    accent1a: Color(0xFFD97706),
    accent1b: Color(0xFF854D0E),
    accent2a: Color(0xFF65A30D),
    accent2b: Color(0xFF3F6212),
    yesColor: Color(0xFF16A34A),
    noColor: Color(0xFFDC2626),
  );

  static const dark = AppThemeColors(
    bgColor1: Color(0xFF020617),
    bgColor2: Color(0xFF0F172A),
    bgColor3: Color(0xFF1E293B),
    textColor1: Color(0xFFF8FAFC),
    textColor2: Color(0xFF94A3B8),
    accent1a: Color(0xFFFBBF24),
    accent1b: Color(0xFFFEF08A),
    accent2a: Color(0xFFA3E635),
    accent2b: Color(0xFFD9F99D),
    yesColor: Color(0xFF4ADE80),
    noColor: Color(0xFFF87171),
  );

  @override
  AppThemeColors copyWith({
    Color? bgColor1,
    Color? bgColor2,
    Color? bgColor3,
    Color? textColor1,
    Color? textColor2,
    Color? accent1a,
    Color? accent1b,
    Color? accent2a,
    Color? accent2b,
    Color? yesColor,
    Color? noColor,
  }) {
    return AppThemeColors(
      bgColor1: bgColor1 ?? this.bgColor1,
      bgColor2: bgColor2 ?? this.bgColor2,
      bgColor3: bgColor3 ?? this.bgColor3,
      textColor1: textColor1 ?? this.textColor1,
      textColor2: textColor2 ?? this.textColor2,
      accent1a: accent1a ?? this.accent1a,
      accent1b: accent1b ?? this.accent1b,
      accent2a: accent2a ?? this.accent2a,
      accent2b: accent2b ?? this.accent2b,
      yesColor: yesColor ?? this.yesColor,
      noColor: noColor ?? this.noColor,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      bgColor1: Color.lerp(bgColor1, other.bgColor1, t)!,
      bgColor2: Color.lerp(bgColor2, other.bgColor2, t)!,
      bgColor3: Color.lerp(bgColor3, other.bgColor3, t)!,
      textColor1: Color.lerp(textColor1, other.textColor1, t)!,
      textColor2: Color.lerp(textColor2, other.textColor2, t)!,
      accent1a: Color.lerp(accent1a, other.accent1a, t)!,
      accent1b: Color.lerp(accent1b, other.accent1b, t)!,
      accent2a: Color.lerp(accent2a, other.accent2a, t)!,
      accent2b: Color.lerp(accent2b, other.accent2b, t)!,
      yesColor: Color.lerp(yesColor, other.yesColor, t)!,
      noColor: Color.lerp(noColor, other.noColor, t)!,
    );
  }
}

class AppTheme {
  static ThemeData light() {
    final c = AppThemeColors.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: c.accent2a,
      brightness: Brightness.light,
      primary: c.accent2a,
      secondary: c.accent1a,
      surface: c.bgColor2,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bgColor1,
      cardColor: c.bgColor2,
      dividerTheme: DividerThemeData(color: c.bgColor3),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgColor1,
        foregroundColor: c.textColor1,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.bgColor1,
        indicatorColor: c.bgColor3,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: c.textColor2, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? c.accent2a : c.textColor2);
        }),
      ),
      textTheme: const TextTheme().apply(
        bodyColor: c.textColor1,
        displayColor: c.textColor1,
      ),
      extensions: const [AppThemeColors.light],
    );
  }

  static ThemeData dark() {
    final c = AppThemeColors.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: c.accent2a,
      brightness: Brightness.dark,
      primary: c.accent2a,
      secondary: c.accent1a,
      surface: c.bgColor2,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bgColor1,
      cardColor: c.bgColor2,
      dividerTheme: DividerThemeData(color: c.bgColor3),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgColor1,
        foregroundColor: c.textColor1,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.bgColor1,
        indicatorColor: c.bgColor3,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: c.textColor2, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? c.accent2a : c.textColor2);
        }),
      ),
      textTheme: const TextTheme().apply(
        bodyColor: c.textColor1,
        displayColor: c.textColor1,
      ),
      extensions: const [AppThemeColors.dark],
    );
  }
}

/// Easy access: `final c = context.appColors;`
extension AppThemeX on BuildContext {
  AppThemeColors get appColors => Theme.of(this).extension<AppThemeColors>()!;
}

/// Controls ThemeMode (Terang / Sistem / Gelap)
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}

/// Provide ThemeController to the widget tree.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found. Wrap your app with ThemeScope.');
    return scope!.notifier!;
  }
}

class TextScaleController extends ChangeNotifier {
  // 1.0 = normal, 1.5 = besar
  double _scale = 1.0;

  double get scale => _scale;

  void setScale(double scale) {
    if (_scale == scale) return;
    _scale = scale;
    notifyListeners();
  }
}

class TextScaleScope extends InheritedNotifier<TextScaleController> {
  const TextScaleScope({
    super.key,
    required TextScaleController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static TextScaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TextScaleScope>();
    assert(scope != null, 'TextScaleScope not found. Wrap your app with TextScaleScope.');
    return scope!.notifier!;
  }
}