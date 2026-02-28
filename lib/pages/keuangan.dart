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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title berhasil diperbarui')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    }
  }

  Widget _moneyCard({
    required BuildContext context,
    required String title,
    required String valueText,
    VoidCallback? onEdit,
  }) {
    return InfoCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(valueText, style: Theme.of(context).textTheme.titleMedium),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final transaksiStream = FirebaseFirestore.instance
        .collection('keuangan')
        .orderBy('tanggal', descending: false)
        .snapshots(); // existing transaksi source :contentReference[oaicite:3]{index=3}

    final metaRef = FirebaseFirestore.instance
        .collection(_metaCollection)
        .doc(_metaDocId);

    return PageScaffold(
      title: 'Keuangan',
      children: [
        const SectionTitle('Aset Masjid'),

        // 1) Stream transaksi untuk menghitung Kas (saldoKas terakhir)
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

            // Compute saldo in chronological order FIRST (so Kas always correct)
            int saldo = 0;
            final rowsChrono = <_Row>[];
            for (final r in baseRows) {
              saldo = saldo + r.masuk - r.keluar;
              rowsChrono.add(_Row.fromBase(r, saldoKas: saldo));
            }

            final kasLatest = rowsChrono.isNotEmpty ? rowsChrono.last.saldoKas : 0;

            // Display rows (maybe reversed)
            final rows = newestFirst ? rowsChrono.reversed.toList() : rowsChrono;

            // 2) Stream meta doc for Tabungan & Deposito
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: metaRef.snapshots(),
              builder: (context, metaSnap) {
                // If doc doesn't exist yet, initialize defaults once.
                if (metaSnap.hasData && metaSnap.data != null && !metaSnap.data!.exists) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    metaRef.set(
                      {'tabungan': _defaultTabungan, 'deposito': _defaultDeposito},
                      SetOptions(merge: true),
                    );
                  });
                }

                final meta = metaSnap.data?.data() ?? const <String, dynamic>{};
                final tabungan = (meta['tabungan'] as num?)?.toInt() ?? _defaultTabungan;
                final deposito = (meta['deposito'] as num?)?.toInt() ?? _defaultDeposito;
                final saldoTotal = kasLatest + tabungan + deposito;

                // --- Table UI (your existing Option B) ---
                final hController = ScrollController();
                final dividerColor = Theme.of(context).dividerColor;
                final c = context.appColors;

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

                final rightWidth =
                    colTanggal + colMasuk + colKeluar + colSaldo + colNota;

                // ✅ inner radius = card radius - card padding (from InfoCard) :contentReference[oaicite:4]{index=4}
                final double innerR = (InfoCard.radius - InfoCard.paddingAll)
                    .clamp(0.0, InfoCard.radius);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Summary cards ---
                    _moneyCard(
                      context: context,
                      title: 'Kas',
                      valueText: formatRupiah(kasLatest),
                    ),
                    const SizedBox(height: 12),

                    _moneyCard(
                      context: context,
                      title: 'Tabungan',
                      valueText: formatRupiah(tabungan),
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
                    ),

                    const SizedBox(height: 16),
                    const SectionTitle('Transaksi Harian'),

                    // --- Transactions table card ---
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
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(color: c.yesColor),
                                              ),
                                              dataCell(
                                                formatRupiah(r.keluar),
                                                w: colKeluar,
                                                align: Alignment.centerRight,
                                                bgColor: bg,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(color: c.noColor),
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