import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/common.dart';

class KeuanganPage extends StatelessWidget {
  const KeuanganPage({super.key});

  // ✅ Choose how you want to DISPLAY rows.
  // false = oldest -> newest (first to last)
  // true  = newest -> oldest (last to first)
  static const bool newestFirst = false;

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  static final _tanggalFmt = DateFormat('d MMMM y', 'id_ID');

  String formatRupiah(num value) => _rupiah.format(value);
  String formatTanggal(DateTime dt) => _tanggalFmt.format(dt);

  @override
  Widget build(BuildContext context) {
    // We fetch ordered by timestamp, then we can display either direction.
    // (One orderBy only, so no composite index needed.)
    final stream = FirebaseFirestore.instance
        .collection('keuangan')
        .orderBy('tanggal', descending: false) // base order: oldest->newest
        .snapshots();

    return PageScaffold(
      title: 'Keuangan',
      children: [
        const SectionTitle('Kas Masjid'),
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
              if (docs.isEmpty) {
                return const Text('Belum ada data transaksi.');
              }

              // Step 1: parse documents into rows in base order (oldest->newest)
              final baseRows = <_KeuanganBaseRow>[];
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

                baseRows.add(
                  _KeuanganBaseRow(
                    keterangan: keterangan,
                    tanggal: tanggal,
                    masuk: masuk,
                    keluar: keluar,
                    notaUrl: notaUrl,
                  ),
                );
              }

              // Step 2: choose display order
              final displayRows = newestFirst ? baseRows.reversed.toList() : baseRows;

              // Step 3: compute saldo from TOP to BOTTOM (display order)
              final computedRows = <_KeuanganRow>[];
              int saldo = 0;
              for (final r in displayRows) {
                saldo = saldo + r.masuk - r.keluar;
                computedRows.add(
                  _KeuanganRow(
                    keterangan: r.keterangan,
                    tanggal: r.tanggal,
                    masuk: r.masuk,
                    keluar: r.keluar,
                    saldoKas: saldo,
                    notaUrl: r.notaUrl,
                  ),
                );
              }

              final hController = ScrollController();

              return Scrollbar(
                controller: hController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: hController,
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  dragStartBehavior: DragStartBehavior.down,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Keterangan')),
                      DataColumn(label: Text('Tanggal')),
                      DataColumn(
                        label: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Masuk'),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Keluar'),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Saldo Kas'),
                        ),
                        numeric: true,
                      ),
                      DataColumn(label: Text('Nota')),
                    ],
                    rows: computedRows.map((r) {
                      return DataRow(
                        cells: [
                          DataCell(Text(r.keterangan)),
                          DataCell(Text(formatTanggal(r.tanggal))),
                          DataCell(
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(formatRupiah(r.masuk)),
                            ),
                          ),
                          DataCell(
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(formatRupiah(r.keluar)),
                            ),
                          ),
                          DataCell(
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(formatRupiah(r.saldoKas)),
                            ),
                          ),
                          DataCell(
                            TextButton(
                              onPressed: r.notaUrl.isNotEmpty ? () {} : null,
                              child: const Text('Lihat'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _KeuanganBaseRow {
  final String keterangan;
  final DateTime tanggal;
  final int masuk;
  final int keluar;
  final String notaUrl;

  const _KeuanganBaseRow({
    required this.keterangan,
    required this.tanggal,
    required this.masuk,
    required this.keluar,
    required this.notaUrl,
  });
}

class _KeuanganRow extends _KeuanganBaseRow {
  final int saldoKas;

  const _KeuanganRow({
    required super.keterangan,
    required super.tanggal,
    required super.masuk,
    required super.keluar,
    required super.notaUrl,
    required this.saldoKas,
  });
}