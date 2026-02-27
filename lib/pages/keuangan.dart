import 'package:cloud_firestore/cloud_firestore.dart';
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
    final stream = FirebaseFirestore.instance
        .collection('keuangan')
        .orderBy('tanggal', descending: true)
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

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
                  rows: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final keterangan = (data['keterangan'] ?? '').toString();

                    // Firestore Timestamp -> DateTime
                    final ts = data['tanggal'];
                    final tanggal = (ts is Timestamp)
                        ? ts.toDate()
                        : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime(1970);

                    // Store numbers as int in Firestore
                    final masuk = (data['masuk'] as num?) ?? 0;
                    final keluar = (data['keluar'] as num?) ?? 0;
                    final saldoKas = (data['saldoKas'] as num?) ?? 0;

                    final notaUrl = (data['notaUrl'] ?? '').toString();

                    return DataRow(
                      cells: [
                        DataCell(Text(keterangan)),
                        DataCell(Text(formatTanggal(tanggal))),

                        // ✅ Right-aligned currency
                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(formatRupiah(masuk)),
                          ),
                        ),
                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(formatRupiah(keluar)),
                          ),
                        ),
                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(formatRupiah(saldoKas)),
                          ),
                        ),

                        DataCell(
                          TextButton(
                            onPressed: notaUrl.isNotEmpty ? () {
                              // TODO later: open notaUrl
                            } : null, // disabled when empty
                            child: const Text('Lihat'),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}