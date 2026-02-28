import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../widgets/common.dart';
import '../widgets/controls.dart';

// ---------- Friday rollup model (top-level, not nested) ----------
class _FridayAgg {
  final int weekIndex; // 1..5
  final bool exists; // true if this Friday exists in the month
  final int masuk;
  final int keluar;

  const _FridayAgg({
    required this.weekIndex,
    required this.exists,
    required this.masuk,
    required this.keluar,
  });
}

class KeuanganPage extends StatefulWidget {
  const KeuanganPage({super.key});

  @override
  State<KeuanganPage> createState() => _KeuanganPageState();
}

class _KeuanganPageState extends State<KeuanganPage> {
  // false = oldest->newest, true = newest->oldest
  static const bool newestFirst = false;

  // Firestore doc for tabungan & deposito (manual values)
  static const String _metaCollection = 'keuangan_meta';
  static const String _metaDocId = 'ringkasan';
  static const int _defaultTabungan = 87656000;
  static const int _defaultDeposito = 102752000;

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );
  static final _tanggalFmt = DateFormat('d MMMM y', 'id_ID');

  String formatRupiah(num value) => _rupiah.format(value);
  String formatTanggal(DateTime dt) => _tanggalFmt.format(dt);

  // Column widths (tweak as you like)
  static const double colKet = 150;
  static const double colTanggal = 170;
  static const double colMasuk = 170;
  static const double colKeluar = 170;
  static const double colSaldo = 150;
  static const double colNota = 90;
  static const double rowH = 52;

  // Friday summary widths (no horizontal scroll)
  static const double colJumatIdx = 160;

  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _setMonth(DateTime m) {
    setState(() => _selectedMonth = DateTime(m.year, m.month));
  }

  int _parseMoney(String s) {
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  Future<void> _editMoneyField({
    required BuildContext context,
    required DocumentReference<Map<String, dynamic>> docRef,
    required String title,
    required String fieldName,
    required int currentValue,
  }) async {
    // ✅ capture messenger BEFORE the await to avoid context-across-async-gap warning
    final messenger = ScaffoldMessenger.of(context);

    final controller = TextEditingController(text: currentValue.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Ubah $title'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Masukkan angka, contoh: 87656000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final v = _parseMoney(controller.text);
                Navigator.pop(ctx, v);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      await docRef.set({fieldName: result}, SetOptions(merge: true));
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$title berhasil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  Widget _moneyCard({
    required BuildContext context,
    required String title,
    required String valueText,
    required Color bgColor,
    VoidCallback? onEdit,
  }) {
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InfoCard.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(InfoCard.paddingAll),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      valueText,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                tooltip: 'Ubah $title',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
      ),
    );
  }

  bool _isInSelectedMonth(DateTime d) =>
      d.year == _selectedMonth.year && d.month == _selectedMonth.month;

  // ---------- Friday rollup helpers ----------
  int _daysInMonth(int year, int month) {
    final firstNextMonth =
    (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstNextMonth.subtract(const Duration(days: 1)).day;
  }

  List<DateTime> _fridaysInMonth(int year, int month) {
    final days = _daysInMonth(year, month);
    final result = <DateTime>[];
    for (int d = 1; d <= days; d++) {
      final dt = DateTime(year, month, d);
      if (dt.weekday == DateTime.friday) result.add(dt);
    }
    return result;
  }

  DateTime _atTime(DateTime d, int hour, int minute) =>
      DateTime(d.year, d.month, d.day, hour, minute);

  List<_FridayAgg> _computeFridayAggs({
    required int year,
    required int month,
    required List<_BaseRow> baseRows,
  }) {
    final fridays = _fridaysInMonth(year, month);
    final out = <_FridayAgg>[];

    for (int i = 0; i < 5; i++) {
      final weekIndex = i + 1;

      if (i >= fridays.length) {
        // ✅ No such Friday in this month → keep row, but placeholder
        out.add(
          const _FridayAgg(weekIndex: 0, exists: false, masuk: 0, keluar: 0),
        );
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

        final within =
            t.isAfter(start) && (t.isBefore(end) || t.isAtSameMomentAs(end));
        if (!within) continue;

        totalMasuk += r.masuk;
        totalKeluar += r.keluar;
      }

      out.add(
        _FridayAgg(
          weekIndex: weekIndex,
          exists: true,
          masuk: totalMasuk,
          keluar: totalKeluar,
        ),
      );
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final transaksiStream = FirebaseFirestore.instance
        .collection('keuangan')
        .orderBy('tanggal', descending: false)
        .snapshots();

    final metaRef = FirebaseFirestore.instance
        .collection(_metaCollection)
        .doc(_metaDocId);

    // Admin document: config/admins { emails: { "email@domain": true } }
    final adminDoc =
    FirebaseFirestore.instance.collection('config').doc('admins');

    // ✅ Option A: reactive admin check (stream)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: adminDoc.snapshots(),
          builder: (context, adminSnap) {
            final adminData =
                adminSnap.data?.data() ?? const <String, dynamic>{};
            final emails = (adminData['emails'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final isAdmin = user != null && emails[user.email] == true;

            return PageScaffold(
              title: 'Keuangan',
              children: [
                const SectionTitle('Aset Masjid', level: 1),
                StreamBuilder<QuerySnapshot>(
                  stream: transaksiStream,
                  builder: (context, txSnap) {
                    if (txSnap.hasError) {
                      return Text('Gagal memuat data: ${txSnap.error}');
                    }
                    if (!txSnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final docs = txSnap.data!.docs;
                    if (docs.isEmpty) return const Text('Belum ada data transaksi.');

                    // Parse base rows (chronological)
                    final baseRows = <_BaseRow>[];
                    for (final doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final keterangan = (data['keterangan'] ?? '').toString();

                      final ts = data['tanggal'];
                      final tanggal = (ts is Timestamp)
                          ? ts.toDate()
                          : DateTime.tryParse(ts?.toString() ?? '') ??
                          DateTime(1970);

                      final masuk = (data['masuk'] as num?)?.toInt() ?? 0;
                      final keluar = (data['keluar'] as num?)?.toInt() ?? 0;
                      final notaUrl = (data['notaUrl'] ?? '').toString();

                      baseRows.add(_BaseRow(
                        keterangan: keterangan,
                        tanggal: tanggal,
                        masuk: masuk,
                        keluar: keluar,
                        notaUrl: notaUrl,
                      ));
                    }

                    // Compute saldo across ALL transactions first (so Kas and saldoKas stay consistent)
                    int saldo = 0;
                    final rowsChrono = <_Row>[];
                    for (final r in baseRows) {
                      saldo = saldo + r.masuk - r.keluar;
                      rowsChrono.add(_Row.fromBase(r, saldoKas: saldo));
                    }

                    final kasLatest =
                    rowsChrono.isNotEmpty ? rowsChrono.last.saldoKas : 0;

                    // Filter rows for selected month (table only)
                    final filteredChrono =
                    rowsChrono.where((r) => _isInSelectedMonth(r.tanggal)).toList();

                    // ✅ Restore Evaluasi Bulanan totals
                    final totalMasukBulan =
                    filteredChrono.fold<int>(0, (s, r) => s + r.masuk);
                    final totalKeluarBulan =
                    filteredChrono.fold<int>(0, (s, r) => s + r.keluar);
                    final diffBulan = totalMasukBulan - totalKeluarBulan;

                    final rows = newestFirst ? filteredChrono.reversed.toList() : filteredChrono;

                    // Friday aggregations for selected month (computed from ALL rows)
                    final fridayAggs = _computeFridayAggs(
                      year: _selectedMonth.year,
                      month: _selectedMonth.month,
                      baseRows: baseRows,
                    );

                    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: metaRef.snapshots(),
                      builder: (context, metaSnap) {
                        // Initialize defaults if missing
                        if (metaSnap.hasData &&
                            metaSnap.data != null &&
                            !metaSnap.data!.exists) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            metaRef.set(
                              {
                                'tabungan': _defaultTabungan,
                                'deposito': _defaultDeposito,
                              },
                              SetOptions(merge: true),
                            );
                          });
                        }

                        final meta =
                            metaSnap.data?.data() ?? const <String, dynamic>{};
                        final tabungan =
                            (meta['tabungan'] as num?)?.toInt() ?? _defaultTabungan;
                        final deposito =
                            (meta['deposito'] as num?)?.toInt() ?? _defaultDeposito;
                        final saldoTotal = kasLatest + tabungan + deposito;

                        final hController = ScrollController();
                        final dividerColor = Theme.of(context).dividerColor;
                        final c = context.appColors;

                        final monoNumStyle =
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontFeatures: const [FontFeature.tabularFigures()],
                        );

                        Color keteranganBg(int i) => (i % 2 == 0)
                            ? c.accent1a.withAlpha(64)
                            : c.accent2a.withAlpha(64);

                        Color otherColsBg(int i) => (i % 2 == 0)
                            ? c.accent1a.withAlpha(32)
                            : c.accent2a.withAlpha(32);

                        Widget headerCell(
                            String text, {
                              required double w,
                              Alignment align = Alignment.centerLeft,
                            }) {
                          return Container(
                            width: w,
                            height: rowH,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: align,
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: dividerColor)),
                            ),
                            child: Text(
                              text,
                              style: Theme.of(context).textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }

                        Widget dataCell(
                            String text, {
                              required double w,
                              Alignment align = Alignment.centerLeft,
                              TextStyle? style,
                              Color? bgColor,
                            }) {
                          return Container(
                            width: w,
                            height: rowH,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: align,
                            decoration: BoxDecoration(color: bgColor),
                            child: Text(
                              text,
                              overflow: TextOverflow.ellipsis,
                              style: style,
                            ),
                          );
                        }

                        final rightWidth =
                            colTanggal + colMasuk + colKeluar + colSaldo + colNota;

                        final double innerR =
                        (InfoCard.radius - InfoCard.paddingAll)
                            .clamp(0.0, InfoCard.radius);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _moneyCard(
                              context: context,
                              title: 'Kas',
                              valueText: formatRupiah(kasLatest),
                              bgColor: c.accent2a.withAlpha(64),
                            ),
                            const SizedBox(height: 12),
                            _moneyCard(
                              context: context,
                              title: 'Tabungan',
                              valueText: formatRupiah(tabungan),
                              bgColor: c.accent2a.withAlpha(64),
                              onEdit: isAdmin
                                  ? () => _editMoneyField(
                                context: context,
                                docRef: metaRef,
                                title: 'Tabungan',
                                fieldName: 'tabungan',
                                currentValue: tabungan,
                              )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _moneyCard(
                              context: context,
                              title: 'Deposito',
                              valueText: formatRupiah(deposito),
                              bgColor: c.accent2a.withAlpha(64),
                              onEdit: isAdmin
                                  ? () => _editMoneyField(
                                context: context,
                                docRef: metaRef,
                                title: 'Deposito',
                                fieldName: 'deposito',
                                currentValue: deposito,
                              )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _moneyCard(
                              context: context,
                              title: 'Saldo',
                              valueText: formatRupiah(saldoTotal),
                              bgColor: c.accent2a.withAlpha(96),
                            ),
                            const SizedBox(height: 16),
                            const SectionTitle('Neraca Bulanan', level: 1),
                            const SizedBox(height: 12),

                            MonthSwitcher(
                              selectedMonth: _selectedMonth,
                              onChanged: _setMonth,
                              locale: 'id_ID',
                            ),

                            const SizedBox(height: 12),
                            const SectionTitle("Transaksi Per Jum'at", level: 2),

                            // No horizontal scroll table (2 cols, 5 rows)
                            InfoCard(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(innerR),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Header
                                    Row(
                                      children: [
                                        headerCell("Jum'at",
                                            w: colJumatIdx, align: Alignment.center),
                                        Expanded(
                                          child: Container(
                                            height: rowH,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            alignment: Alignment.centerLeft,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                  bottom: BorderSide(color: dividerColor)),
                                            ),
                                            child: Text(
                                              'Neraca',
                                              style:
                                              Theme.of(context).textTheme.titleSmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // 5 rows
                                    ...List.generate(5, (i) {
                                      final agg = fridayAggs[i];
                                      final bg = otherColsBg(i);

                                      final jumatText = agg.exists ? '${i + 1}' : '-';
                                      final masukText =
                                      agg.exists ? formatRupiah(agg.masuk) : '-';
                                      final keluarText = agg.exists
                                          ? 'Rp. -${NumberFormat.decimalPattern('id_ID').format(agg.keluar)}'
                                          : '-';

                                      return Row(
                                        children: [
                                          dataCell(
                                            jumatText,
                                            w: colJumatIdx,
                                            align: Alignment.center,
                                            bgColor: bg,
                                            style: monoNumStyle,
                                          ),
                                          Expanded(
                                            child: Container(
                                              height: rowH,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(color: bg),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    masukText,
                                                    textAlign: TextAlign.right,
                                                    style: agg.exists
                                                        ? monoNumStyle?.copyWith(
                                                        color: c.yesColor)
                                                        : monoNumStyle,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    keluarText,
                                                    textAlign: TextAlign.right,
                                                    style: agg.exists
                                                        ? monoNumStyle?.copyWith(
                                                        color: c.noColor)
                                                        : monoNumStyle,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),

                            // ✅ RESTORED: Evaluasi Bulanan (donut)
                            const SizedBox(height: 12),
                            const SectionTitle('Evaluasi Bulanan', level: 2),

                            InfoCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Neraca Bulan ${DateFormat('MMMM y', 'id_ID').format(_selectedMonth)}',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: _DonutChart(
                                      masuk: totalMasukBulan,
                                      keluar: totalKeluarBulan,
                                      masukColor: c.yesColor,
                                      keluarColor: c.noColor,
                                      centerTextColor: c.textColor2,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _LegendRow(
                                    dotColor: c.yesColor,
                                    title: 'Pemasukan',
                                    value: formatRupiah(totalMasukBulan),
                                  ),
                                  const SizedBox(height: 10),
                                  _LegendRow(
                                    dotColor: c.noColor,
                                    title: 'Pengeluaran',
                                    value: formatRupiah(totalKeluarBulan),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          diffBulan >= 0 ? 'Surplus' : 'Defisit',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Text(
                                        formatRupiah(diffBulan.abs()),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                          fontFamily: 'monospace',
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                          color: diffBulan >= 0
                                              ? c.yesColor
                                              : c.noColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            const SectionTitle('Transaksi Harian', level: 2),

                            if (rows.isEmpty)
                              const InfoCard(
                                child: Text('Tidak ada transaksi pada bulan ini.'),
                              )
                            else
                              InfoCard(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(innerR),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: colKet,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            headerCell('Keterangan', w: colKet),
                                            ...List.generate(rows.length, (i) {
                                              final r = rows[i];
                                              return dataCell(
                                                r.keterangan,
                                                w: colKet,
                                                bgColor: keteranganBg(i),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Scrollbar(
                                          controller: hController,
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            controller: hController,
                                            scrollDirection: Axis.horizontal,
                                            physics: const AlwaysScrollableScrollPhysics(),
                                            dragStartBehavior: DragStartBehavior.down,
                                            child: SizedBox(
                                              width: rightWidth,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    children: [
                                                      headerCell('Tanggal', w: colTanggal),
                                                      headerCell(
                                                        'Masuk',
                                                        w: colMasuk,
                                                        align: Alignment.centerRight,
                                                      ),
                                                      headerCell(
                                                        'Keluar',
                                                        w: colKeluar,
                                                        align: Alignment.centerRight,
                                                      ),
                                                      headerCell(
                                                        'Saldo Kas',
                                                        w: colSaldo,
                                                        align: Alignment.centerRight,
                                                      ),
                                                      headerCell('Nota', w: colNota),
                                                    ],
                                                  ),
                                                  ...List.generate(rows.length, (i) {
                                                    final r = rows[i];
                                                    final bg = otherColsBg(i);

                                                    return Row(
                                                      children: [
                                                        dataCell(
                                                          formatTanggal(r.tanggal),
                                                          w: colTanggal,
                                                          bgColor: bg,
                                                        ),
                                                        dataCell(
                                                          formatRupiah(r.masuk),
                                                          w: colMasuk,
                                                          align: Alignment.centerRight,
                                                          bgColor: bg,
                                                          style: monoNumStyle?.copyWith(
                                                            color: c.yesColor,
                                                          ),
                                                        ),
                                                        dataCell(
                                                          formatRupiah(r.keluar),
                                                          w: colKeluar,
                                                          align: Alignment.centerRight,
                                                          bgColor: bg,
                                                          style: monoNumStyle?.copyWith(
                                                            color: c.noColor,
                                                          ),
                                                        ),
                                                        dataCell(
                                                          formatRupiah(r.saldoKas),
                                                          w: colSaldo,
                                                          align: Alignment.centerRight,
                                                          bgColor: bg,
                                                          style: monoNumStyle,
                                                        ),
                                                        Container(
                                                          width: colNota,
                                                          height: rowH,
                                                          alignment: Alignment.center,
                                                          decoration: BoxDecoration(color: bg),
                                                          child: TextButton(
                                                            onPressed: r.notaUrl.isNotEmpty
                                                                ? () {
                                                              /* TODO */
                                                            }
                                                                : null,
                                                            child: const Text('Lihat'),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

// ----------------- Donut (Evaluasi Bulanan) -----------------

class _DonutChart extends StatelessWidget {
  final int masuk;
  final int keluar;
  final Color masukColor;
  final Color keluarColor;
  final Color centerTextColor; // textColor2

  const _DonutChart({
    required this.masuk,
    required this.keluar,
    required this.masukColor,
    required this.keluarColor,
    required this.centerTextColor,
  });

  static const double _size = 170;
  static const double _stroke = 18;

  @override
  Widget build(BuildContext context) {
    final diff = masuk - keluar;

    final jutaFmt = NumberFormat('0.0', 'id_ID');
    final absJuta = (diff.abs() / 1000000.0);
    final jutaText = jutaFmt.format(absJuta);

    final isSurplus = diff >= 0;
    final diffColor = isSurplus ? masukColor : keluarColor;
    final chevron = isSurplus ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(_size, _size),
            painter: _DonutPainter(
              masuk: masuk,
              keluar: keluar,
              masukColor: masukColor,
              keluarColor: keluarColor,
              stroke: _stroke,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                jutaText,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: diffColor,
                  fontFamily: 'monospace',
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chevron, size: 18, color: diffColor),
                  const SizedBox(width: 4),
                  Text(
                    'Juta',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: centerTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int masuk;
  final int keluar;
  final Color masukColor;
  final Color keluarColor;
  final double stroke;

  _DonutPainter({
    required this.masuk,
    required this.keluar,
    required this.masukColor,
    required this.keluarColor,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = masuk + keluar;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - stroke / 2;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = Colors.white.withAlpha(20);

    // draw faint ring background
    canvas.drawCircle(center, radius, basePaint);

    if (total <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -3.1415926535 / 2; // start at top

    final masukSweep = (masuk / total) * (2 * 3.1415926535);
    final keluarSweep = (keluar / total) * (2 * 3.1415926535);

    final masukPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = masukColor;

    final keluarPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = keluarColor;

    // masuk arc
    canvas.drawArc(rect, startAngle, masukSweep, false, masukPaint);
    // keluar arc immediately after
    canvas.drawArc(rect, startAngle + masukSweep, keluarSweep, false, keluarPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.masuk != masuk ||
        oldDelegate.keluar != keluar ||
        oldDelegate.masukColor != masukColor ||
        oldDelegate.keluarColor != keluarColor ||
        oldDelegate.stroke != stroke;
  }
}

class _LegendRow extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String value;

  const _LegendRow({
    required this.dotColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ----------------- Table models -----------------

class _BaseRow {
  final String keterangan;
  final DateTime tanggal;
  final int masuk;
  final int keluar;
  final String notaUrl;

  const _BaseRow({
    required this.keterangan,
    required this.tanggal,
    required this.masuk,
    required this.keluar,
    required this.notaUrl,
  });
}

class _Row extends _BaseRow {
  final int saldoKas;

  const _Row({
    required super.keterangan,
    required super.tanggal,
    required super.masuk,
    required super.keluar,
    required super.notaUrl,
    required this.saldoKas,
  });

  factory _Row.fromBase(_BaseRow b, {required int saldoKas}) {
    return _Row(
      keterangan: b.keterangan,
      tanggal: b.tanggal,
      masuk: b.masuk,
      keluar: b.keluar,
      notaUrl: b.notaUrl,
      saldoKas: saldoKas,
    );
  }
}