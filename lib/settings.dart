import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsKeys {
  static const themeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const textScale = 'text_scale'; // double, e.g. 1.0 or 1.5
}

class SettingsService {
  final SharedPreferences prefs;
  SettingsService(this.prefs);

  ThemeMode loadThemeMode() {
    final raw = prefs.getString(SettingsKeys.themeMode) ?? 'system';
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(SettingsKeys.themeMode, raw);
  }

  double loadTextScale() {
    return prefs.getDouble(SettingsKeys.textScale) ?? 1.0;
  }

  Future<void> saveTextScale(double scale) async {
    await prefs.setDouble(SettingsKeys.textScale, scale);
  }
}

class SettingsController extends ChangeNotifier {
  final SettingsService _service;

  ThemeMode _themeMode;
  double _textScale;

  SettingsController(this._service)
      : _themeMode = _service.loadThemeMode(),
        _textScale = _service.loadTextScale();

  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _service.saveThemeMode(mode);
  }

  Future<void> setTextScale(double scale) async {
    if (_textScale == scale) return;
    _textScale = scale;
    notifyListeners();
    await _service.saveTextScale(scale);
  }
}

class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static SettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope not found. Wrap your app with SettingsScope.');
    return scope!.notifier!;
  }
}