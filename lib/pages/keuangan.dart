import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/common.dart';
import '../widgets/controls.dart';

import 'widgets_keuangan/keu_models.dart';
import 'widgets_keuangan/keu_helpers.dart';
import 'widgets_keuangan/keu_format.dart';
import 'widgets_keuangan/keu_state.dart';
import 'widgets_keuangan/keu_theme.dart';

import 'widgets_keuangan/asset_cards.dart';
import 'widgets_keuangan/friday_table.dart';
import 'widgets_keuangan/monthly_eval.dart';
import 'widgets_keuangan/daily_table.dart';

class KeuanganPage extends StatefulWidget {
  const KeuanganPage({super.key});

  @override
  State<KeuanganPage> createState() => _KeuanganPageState();
}

class _KeuanganPageState extends State<KeuanganPage> {
  static const bool newestFirst = false;

  static const String _metaCollection = 'keuangan_meta';
  static const String _metaDocId = 'ringkasan';
  static const int _defaultTabungan = 87656000;
  static const int _defaultDeposito = 102752000;

  late DateTime _selectedMonth;
  final _fmt = KeuFormat();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _setMonth(DateTime m) => setState(() => _selectedMonth = DateTime(m.year, m.month));

  double _innerR() => (InfoCard.radius - InfoCard.paddingAll).clamp(0.0, InfoCard.radius);

  @override
  Widget build(BuildContext context) {
    final transaksiStream = FirebaseFirestore.instance
        .collection('keuangan')
        .orderBy('tanggal', descending: false)
        .snapshots();

    final metaRef = FirebaseFirestore.instance.collection(_metaCollection).doc(_metaDocId);
    final adminDoc = FirebaseFirestore.instance.collection('config').doc('admins');

    final innerR = _innerR();
    final keuTheme = KeuTheme.from(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: adminDoc.snapshots(),
          builder: (context, adminSnap) {
            final adminData = adminSnap.data?.data() ?? const <String, dynamic>{};
            final emails = (adminData['emails'] as Map?)?.cast<String, dynamic>() ?? const {};
            final isAdmin = user != null && emails[user.email] == true;

            return PageScaffold(
              title: 'Keuangan',
              children: [
                const SectionTitle('Aset Masjid', level: 1),

                StreamBuilder<QuerySnapshot>(
                  stream: transaksiStream,
                  builder: (context, txSnap) {
                    if (txSnap.hasError) return Text('Gagal memuat data: ${txSnap.error}');
                    if (!txSnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final docs = txSnap.data!.docs;
                    if (docs.isEmpty) return const Text('Belum ada data transaksi.');

                    final baseRows = <BaseRow>[];
                    for (final doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final keterangan = (data['keterangan'] ?? '').toString();

                      final ts = data['tanggal'];
                      final tanggal = (ts is Timestamp)
                          ? ts.toDate()
                          : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime(1970);

                      baseRows.add(BaseRow(
                        keterangan: keterangan,
                        tanggal: tanggal,
                        masuk: (data['masuk'] as num?)?.toInt() ?? 0,
                        keluar: (data['keluar'] as num?)?.toInt() ?? 0,
                        notaUrl: (data['notaUrl'] ?? '').toString(),
                      ));
                    }

                    int saldo = 0;
                    final rowsChrono = <RowWithSaldo>[];
                    for (final r in baseRows) {
                      saldo = saldo + r.masuk - r.keluar;
                      rowsChrono.add(RowWithSaldo.fromBase(r, saldoKas: saldo));
                    }

                    final kasLatest = rowsChrono.isNotEmpty ? rowsChrono.last.saldoKas : 0;

                    final filteredChrono = rowsChrono
                        .where((r) => KeuHelpers.isInMonth(r.tanggal, _selectedMonth))
                        .toList();

                    final rowsForMonth =
                    newestFirst ? filteredChrono.reversed.toList() : filteredChrono;

                    final totalMasukBulan =
                    filteredChrono.fold<int>(0, (s, r) => s + r.masuk);
                    final totalKeluarBulan =
                    filteredChrono.fold<int>(0, (s, r) => s + r.keluar);
                    final diffBulan = totalMasukBulan - totalKeluarBulan;

                    final fridayAggs = KeuHelpers.computeFridayAggs(
                      year: _selectedMonth.year,
                      month: _selectedMonth.month,
                      baseRows: baseRows,
                    );

                    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: metaRef.snapshots(),
                      builder: (context, metaSnap) {
                        // ✅ cleaner default init
                        if (metaSnap.hasData && metaSnap.data != null && !metaSnap.data!.exists) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            KeuHelpers.ensureMetaDefaults(
                              metaRef: metaRef,
                              defaultTabungan: _defaultTabungan,
                              defaultDeposito: _defaultDeposito,
                            );
                          });
                        }

                        final meta = metaSnap.data?.data() ?? const <String, dynamic>{};
                        final tabungan = (meta['tabungan'] as num?)?.toInt() ?? _defaultTabungan;
                        final deposito = (meta['deposito'] as num?)?.toInt() ?? _defaultDeposito;
                        final saldoTotal = kasLatest + tabungan + deposito;

                        final state = KeuState(
                          baseRows: baseRows,
                          rowsChrono: rowsChrono,
                          rowsForMonth: rowsForMonth,
                          fridayAggs: fridayAggs,
                          kasLatest: kasLatest,
                          tabungan: tabungan,
                          deposito: deposito,
                          saldoTotal: saldoTotal,
                          selectedMonth: _selectedMonth,
                          totalMasukBulan: totalMasukBulan,
                          totalKeluarBulan: totalKeluarBulan,
                          diffBulan: diffBulan,
                          isAdmin: isAdmin,
                          metaRef: metaRef,
                          formatRupiah: _fmt.rupiah,
                          formatTanggal: _fmt.tanggal,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            KeuAssetCards(
                              kasLatest: state.kasLatest,
                              tabungan: state.tabungan,
                              deposito: state.deposito,
                              saldoTotal: state.saldoTotal,
                              isAdmin: state.isAdmin,
                              metaRef: state.metaRef,
                              formatRupiah: state.formatRupiah,
                            ),

                            const SizedBox(height: 16),
                            const SectionTitle('Neraca Bulanan', level: 1),
                            const SizedBox(height: 12),

                            MonthSwitcher(
                              selectedMonth: state.selectedMonth,
                              onChanged: _setMonth,
                              locale: 'id_ID',
                            ),

                            const SizedBox(height: 12),
                            const SectionTitle("Transaksi Per Jum'at", level: 2),

                            FridayTable(
                              fridayAggs: state.fridayAggs,
                              formatRupiah: state.formatRupiah,
                              innerR: innerR,
                              theme: keuTheme,
                            ),

                            const SizedBox(height: 12),
                            const SectionTitle('Evaluasi Bulanan', level: 2),

                            MonthlyEval(
                              selectedMonth: state.selectedMonth,
                              totalMasukBulan: state.totalMasukBulan,
                              totalKeluarBulan: state.totalKeluarBulan,
                              diffBulan: state.diffBulan,
                              formatRupiah: state.formatRupiah,
                              innerR: innerR,
                              theme: keuTheme,
                            ),

                            const SizedBox(height: 12),
                            const SectionTitle('Transaksi Harian', level: 2),

                            DailyTable(
                              rows: state.rowsForMonth,
                              formatTanggal: state.formatTanggal,
                              formatRupiah: state.formatRupiah,
                              innerR: innerR,
                              theme: keuTheme,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}