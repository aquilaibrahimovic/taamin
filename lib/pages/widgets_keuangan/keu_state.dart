import 'package:cloud_firestore/cloud_firestore.dart';
import 'keu_models.dart';

class KeuState {
  // data
  final List<BaseRow> baseRows;
  final List<RowWithSaldo> rowsChrono;
  final List<RowWithSaldo> rowsForMonth; // already ordered per UI choice
  final List<FridayAgg> fridayAggs;

  // money
  final int kasLatest;
  final int tabungan;
  final int deposito;
  final int saldoTotal;

  // month stats
  final DateTime selectedMonth;
  final int totalMasukBulan;
  final int totalKeluarBulan;
  final int diffBulan;

  // admin + refs
  final bool isAdmin;
  final DocumentReference<Map<String, dynamic>> metaRef;

  // formatters
  final String Function(num) formatRupiah;
  final String Function(DateTime) formatTanggal;

  const KeuState({
    required this.baseRows,
    required this.rowsChrono,
    required this.rowsForMonth,
    required this.fridayAggs,
    required this.kasLatest,
    required this.tabungan,
    required this.deposito,
    required this.saldoTotal,
    required this.selectedMonth,
    required this.totalMasukBulan,
    required this.totalKeluarBulan,
    required this.diffBulan,
    required this.isAdmin,
    required this.metaRef,
    required this.formatRupiah,
    required this.formatTanggal,
  });
}