import 'package:flutter/material.dart';
import '../../app_theme.dart';

class KeuTheme {
  final Color yesColor;
  final Color noColor;
  final Color textColor2;

  final Color accentRowEven;
  final Color accentRowOdd;
  final Color ketRowEven;
  final Color ketRowOdd;

  const KeuTheme({
    required this.yesColor,
    required this.noColor,
    required this.textColor2,
    required this.accentRowEven,
    required this.accentRowOdd,
    required this.ketRowEven,
    required this.ketRowOdd,
  });

  factory KeuTheme.from(BuildContext context) {
    final c = context.appColors;
    return KeuTheme(
      yesColor: c.yesColor,
      noColor: c.noColor,
      textColor2: c.textColor2,
      accentRowEven: c.accent1a.withAlpha(32),
      accentRowOdd: c.accent2a.withAlpha(32),
      ketRowEven: c.accent1a.withAlpha(64),
      ketRowOdd: c.accent2a.withAlpha(64),
    );
  }
}