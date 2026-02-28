import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../widgets/common.dart';

class KeuanganPage extends StatelessWidget {
  const KeuanganPage({super.key});

  // false = oldest->newest, true = newest->oldest
  static const bool newestFirst = false;

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

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('keuangan')
        .orderBy('tanggal', descending: false)
        .snapshots();

    return PageScaffold(
      title: 'Keuangan',
      children: [
        const SectionTitle('Transaksi Harian'),
        InfoCard(
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Gagal memuat data: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Text('Belum ada data transaksi.');

              // Parse base rows
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

              // Display order
              final displayRows =
              newestFirst ? baseRows.reversed.toList() : baseRows;

              // Compute saldo top->bottom in display order
              int saldo = 0;
              final rows = <_Row>[];
              for (final r in displayRows) {
                saldo = saldo + r.masuk - r.keluar;
                rows.add(_Row.fromBase(r, saldoKas: saldo));
              }

              final hController = ScrollController();
              final dividerColor = Theme.of(context).dividerColor;
              final c = context.appColors;

              // --- Alternating backgrounds ---
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
                    // ✅ no row separator border
                  ),
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                );
              }

              final rightWidth = colTanggal + colMasuk + colKeluar + colSaldo + colNota;

              // ✅ inner radius = card radius - card padding (from InfoCard)
              final double innerR =
              (InfoCard.radius - InfoCard.paddingAll).clamp(0.0, InfoCard.radius);

              return ClipRRect(
                borderRadius: BorderRadius.circular(innerR),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ LEFT: Frozen "Keterangan" column (NOT horizontally scrollable)
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

                    // ✅ RIGHT: Horizontally scrollable columns (NO vertical scrolling)
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
                                // Header row (scrolls horizontally with the body)
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

                                // Data rows (no vertical scrolling; height grows with row count)
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
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.yesColor),
                                      ),
                                      dataCell(
                                        formatRupiah(r.keluar),
                                        w: colKeluar,
                                        align: Alignment.centerRight,
                                        bgColor: bg,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.noColor),
                                      ),
                                      dataCell(
                                        formatRupiah(r.saldoKas),
                                        w: colSaldo,
                                        align: Alignment.centerRight,
                                        bgColor: bg,
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
              );
            },
          ),
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