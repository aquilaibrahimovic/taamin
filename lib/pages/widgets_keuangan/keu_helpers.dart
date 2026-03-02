import 'package:cloud_firestore/cloud_firestore.dart';
import 'keu_models.dart';

class KeuHelpers {
  static bool isInMonth(DateTime d, DateTime month) =>
      d.year == month.year && d.month == month.month;

  static int parseMoney(String s) {
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  /// ✅ Default init helper for meta doc (tabungan/deposito).
  /// Call this once when metaSnap indicates the doc doesn't exist.
  static void ensureMetaDefaults({
    required DocumentReference<Map<String, dynamic>> metaRef,
    required int defaultTabungan,
    required int defaultDeposito,
  }) {
    metaRef.set(
      {
        'tabungan': defaultTabungan,
        'deposito': defaultDeposito,
      },
      SetOptions(merge: true),
    );
  }

  static int _daysInMonth(int year, int month) {
    final firstNextMonth =
    (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstNextMonth.subtract(const Duration(days: 1)).day;
  }

  static List<DateTime> _fridaysInMonth(int year, int month) {
    final days = _daysInMonth(year, month);
    final result = <DateTime>[];
    for (int d = 1; d <= days; d++) {
      final dt = DateTime(year, month, d);
      if (dt.weekday == DateTime.friday) result.add(dt);
    }
    return result;
  }

  static DateTime _atTime(DateTime d, int hour, int minute) =>
      DateTime(d.year, d.month, d.day, hour, minute);

  static List<FridayAgg> computeFridayAggs({
    required int year,
    required int month,
    required List<BaseRow> baseRows,
  }) {
    final fridays = _fridaysInMonth(year, month);
    final out = <FridayAgg>[];

    for (int i = 0; i < 5; i++) {
      final weekIndex = i + 1;

      if (i >= fridays.length) {
        out.add(const FridayAgg(weekIndex: 0, exists: false, date: null, masuk: 0, keluar: 0));
        continue;
      }

      final currentFriday = fridays[i];
      final prevFriday = currentFriday.subtract(const Duration(days: 7));

      // Window: prev Fri 12:01 -> current Fri 12:00
      final start = _atTime(prevFriday, 12, 1);
      final end = _atTime(currentFriday, 12, 0);

      int totalMasuk = 0;
      int totalKeluar = 0;

      for (final r in baseRows) {
        final t = r.tanggal;
        final within = t.isAfter(start) && (t.isBefore(end) || t.isAtSameMomentAs(end));
        if (!within) continue;

        totalMasuk += r.masuk;
        totalKeluar += r.keluar;
      }

      out.add(FridayAgg(
        weekIndex: weekIndex,
        exists: true,
        date: currentFriday, // Pass the date here
        masuk: totalMasuk,
        keluar: totalKeluar,
      ));
    }

    return out;
  }
}