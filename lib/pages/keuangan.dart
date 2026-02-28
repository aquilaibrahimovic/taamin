import 'dart:ui' show FontFeature;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../widgets/common.dart';
import '../widgets/controls.dart'; // ✅ MonthSwitcher + month/year picker

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title berhasil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    final transaksiStream = FirebaseFirestore.instance
        .collection('keuangan')
        .orderBy('tanggal', descending: false)
        .snapshots();

    final metaRef = FirebaseFirestore.instance
        .collection(_metaCollection)
        .doc(_metaDocId);

    return PageScaffold(
      title: 'Keuangan',
      children: [
        const SectionTitle('Aset Masjid'),

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
                  : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime(1970);

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

            final rows =
            newestFirst ? filteredChrono.reversed.toList() : filteredChrono;

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

                final meta = metaSnap.data?.data() ?? const <String, dynamic>{};
                final tabungan =
                    (meta['tabungan'] as num?)?.toInt() ?? _defaultTabungan;
                final deposito =
                    (meta['deposito'] as num?)?.toInt() ?? _defaultDeposito;
                final saldoTotal = kasLatest + tabungan + deposito;

                // --- Table UI (Option B) ---
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
                    decoration: BoxDecoration(
                      color: bgColor,
                    ),
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                  );
                }

                final rightWidth =
                    colTanggal + colMasuk + colKeluar + colSaldo + colNota;

                // Child corner radius = Card radius - Card padding (InfoCard constants)
                final double innerR = (InfoCard.radius - InfoCard.paddingAll)
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
                      onEdit: () => _editMoneyField(
                        context: context,
                        docRef: metaRef,
                        title: 'Tabungan',
                        fieldName: 'tabungan',
                        currentValue: tabungan,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _moneyCard(
                      context: context,
                      title: 'Deposito',
                      valueText: formatRupiah(deposito),
                      bgColor: c.accent2a.withAlpha(64),
                      onEdit: () => _editMoneyField(
                        context: context,
                        docRef: metaRef,
                        title: 'Deposito',
                        fieldName: 'deposito',
                        currentValue: deposito,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _moneyCard(
                      context: context,
                      title: 'Saldo',
                      valueText: formatRupiah(saldoTotal),
                      bgColor: c.accent2a.withAlpha(96),
                    ),
                    const SizedBox(height: 16),

                    const SectionTitle('Neraca Bulanan'),
                    const SizedBox(height: 12),
                    // ✅ Month switcher
                    MonthSwitcher(
                      selectedMonth: _selectedMonth,
                      onChanged: _setMonth,
                      locale: 'id_ID',
                    ),
                    const SizedBox(height: 12),
                    const SectionTitle('Transaksi Harian'),

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
                              // LEFT: Frozen "Keterangan"
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

                              // RIGHT: Horizontally scrollable columns
                              Expanded(
                                child: Scrollbar(
                                  controller: hController,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: hController,
                                    scrollDirection: Axis.horizontal,
                                    physics:
                                    const AlwaysScrollableScrollPhysics(),
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
                                                  decoration:
                                                  BoxDecoration(color: bg),
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
  }
}

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