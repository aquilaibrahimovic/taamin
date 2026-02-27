import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/common.dart';

class KeuanganPage extends StatelessWidget {
  const KeuanganPage({super.key});

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
    // ✅ Use tanggal (timestamp with date+time) as the only ordering source.
    // This avoids the composite index and matches real input/transaction time.
    final stream = FirebaseFirestore.instance
        .collection('keuangan')
        .orderBy('tanggal', descending: false) // oldest -> newest (for saldo calc)
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

              // Build rows with computed saldoKas (running balance)
              final computedRows = <_KeuanganRow>[];
              int saldo = 0;

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

                saldo = saldo + masuk - keluar;

                computedRows.add(
                  _KeuanganRow(
                    keterangan: keterangan,
                    tanggal: tanggal,
                    masuk: masuk,
                    keluar: keluar,
                    saldoKas: saldo,
                    notaUrl: notaUrl,
                  ),
                );
              }

              // Keep newest first in the UI (optional).
              // If you want oldest-first display (input order), remove the .reversed.
              final rowsForDisplay = computedRows;

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
                    rows: rowsForDisplay.map((r) {
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
                              onPressed: r.notaUrl.isNotEmpty
                                  ? () {
                                // TODO later: open r.notaUrl
                              }
                                  : null,
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

class _KeuanganRow {
  final String keterangan;
  final DateTime tanggal;
  final int masuk;
  final int keluar;
  final int saldoKas;
  final String notaUrl;

  const _KeuanganRow({
    required this.keterangan,
    required this.tanggal,
    required this.masuk,
    required this.keluar,
    required this.saldoKas,
    required this.notaUrl,
  });
}