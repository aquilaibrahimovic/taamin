import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../utils/pick_single_image.dart';
import '../widgets/common.dart';
import '../widgets/controls.dart';

import 'widgets_keuangan/asset_cards.dart';
import 'widgets_keuangan/daily_table.dart';
import 'widgets_keuangan/friday_table.dart';
import 'widgets_keuangan/imagekit_uploader.dart';
import 'widgets_keuangan/keu_format.dart';
import 'widgets_keuangan/keu_helpers.dart';
import 'widgets_keuangan/keu_models.dart';
import 'widgets_keuangan/keu_state.dart';
import 'widgets_keuangan/keu_theme.dart';
import 'widgets_keuangan/monthly_eval.dart';
import 'widgets_keuangan/keu_csv.dart';
import 'widgets_keuangan/keu_file_ops.dart';

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
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _setMonth(DateTime m) => setState(() => _selectedMonth = DateTime(m.year, m.month));

  Future<void> _showUpsertTransaksiDialog({RowWithSaldo? row}) async {
    final isEdit = row != null;
    final ketC = TextEditingController(text: row?.keterangan ?? '');
    final masukC = TextEditingController(text: (row?.masuk ?? 0).toString());
    final keluarC = TextEditingController(text: (row?.keluar ?? 0).toString());
    DateTime selected = row?.tanggal ?? DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ketC, decoration: const InputDecoration(labelText: 'Keterangan')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text('Tanggal: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(selected)}')),
                TextButton(
                  onPressed: () async {
                    final picked = await pickDateTime(context, initial: selected);
                    if (picked != null) selected = picked;
                  },
                  child: const Text('Ubah'),
                ),
              ]),
              TextField(controller: masukC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Masuk')),
              TextField(controller: keluarC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Keluar')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );

    if (ok != true) return;
    if (!mounted) return; // ✅ Corrected check

    try {
      final payload = {
        'keterangan': ketC.text.trim(),
        'tanggal': Timestamp.fromDate(selected),
        'masuk': int.tryParse(masukC.text.trim()) ?? 0,
        'keluar': int.tryParse(keluarC.text.trim()) ?? 0
      };
      if (isEdit) {
        await FirebaseFirestore.instance.collection('keuangan').doc(row.docId).set(payload, SetOptions(merge: true));
      } else {
        await FirebaseFirestore.instance.collection('keuangan').add(payload);
      }
      await FirebaseFirestore.instance.collection('notifications').add({
        'message': isEdit ? 'Transaksi ${ketC.text} diubah.' : 'Transaksi ${ketC.text} ditambahkan.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return; // ✅ Fixed line 108 warning
      showAppSnackBar(context, 'Gagal: $e', kind: SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext _) {
    final txStream = FirebaseFirestore.instance.collection('keuangan').orderBy('tanggal').snapshots();
    final metaRef = FirebaseFirestore.instance.collection(_metaCollection).doc(_metaDocId);
    final adminDoc = FirebaseFirestore.instance.collection('config').doc('admins');

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: adminDoc.snapshots(),
          builder: (context, adminSnap) {
            final adminData = adminSnap.data?.data() ?? {};
            final emails = (adminData['emails'] as Map?)?.cast<String, dynamic>() ?? {};
            final isAdmin = user != null && emails[user.email] == true;

            return PageScaffold(
              title: 'Keuangan',
              children: [
                const SectionTitle('Keuangan Masjid', level: 1),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: txStream,
                  builder: (context, txSnap) {
                    if (!txSnap.hasData) return const Center(child: CircularProgressIndicator());

                    final baseRows = txSnap.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return BaseRow(
                        docId: doc.id,
                        keterangan: data['keterangan'] ?? '',
                        tanggal: (data['tanggal'] as Timestamp).toDate(),
                        masuk: (data['masuk'] as num?)?.toInt() ?? 0,
                        keluar: (data['keluar'] as num?)?.toInt() ?? 0,
                        notaUrl: data['notaUrl'] ?? '',
                        notaFileId: data['notaFileId'] ?? '',
                      );
                    }).toList();

                    int runningSaldo = 0;
                    final rowsChrono = baseRows.map((r) {
                      runningSaldo += r.masuk - r.keluar;
                      return RowWithSaldo.fromBase(r, saldoKas: runningSaldo);
                    }).toList();

                    final filtered = rowsChrono.where((r) => KeuHelpers.isInMonth(r.tanggal, _selectedMonth)).toList();
                    final rowsForMonth = newestFirst ? filtered.reversed.toList() : filtered;

                    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: metaRef.snapshots(),
                      builder: (context, metaSnap) {
                        final meta = metaSnap.data?.data() ?? {};
                        final tabungan = (meta['tabungan'] as num?)?.toInt() ?? _defaultTabungan;
                        final deposito = (meta['deposito'] as num?)?.toInt() ?? _defaultDeposito;
                        final kasLatest = rowsChrono.isNotEmpty ? rowsChrono.last.saldoKas : 0;

                        final state = KeuState(
                          baseRows: baseRows,
                          rowsChrono: rowsChrono,
                          rowsForMonth: rowsForMonth,
                          fridayAggs: KeuHelpers.computeFridayAggs(year: _selectedMonth.year, month: _selectedMonth.month, baseRows: baseRows),
                          kasLatest: kasLatest,
                          tabungan: tabungan,
                          deposito: deposito,
                          saldoTotal: kasLatest + tabungan + deposito,
                          selectedMonth: _selectedMonth,
                          totalMasukBulan: filtered.fold(0, (s, r) => s + r.masuk),
                          totalKeluarBulan: filtered.fold(0, (s, r) => s + r.keluar),
                          diffBulan: filtered.fold(0, (s, r) => s + r.masuk - r.keluar),
                          isAdmin: isAdmin,
                          metaRef: metaRef,
                          formatRupiah: _fmt.rupiah,
                          formatTanggal: _fmt.tanggal,
                        );

                        return Column(
                          children: [
                            KeuAssetCards(kasLatest: state.kasLatest, tabungan: state.tabungan, deposito: state.deposito, saldoTotal: state.saldoTotal, isAdmin: state.isAdmin, metaRef: metaRef, formatRupiah: state.formatRupiah),
                            const SizedBox(height: 16),
                            MonthSwitcher(selectedMonth: _selectedMonth, onChanged: _setMonth, locale: 'id_ID'),
                            MonthlyEval(selectedMonth: _selectedMonth, totalMasukBulan: state.totalMasukBulan, totalKeluarBulan: state.totalKeluarBulan, diffBulan: state.diffBulan, formatRupiah: state.formatRupiah, innerR: 12, theme: KeuTheme.from(context)),
                            FridayTable(fridayAggs: state.fridayAggs, formatRupiah: state.formatRupiah, innerR: 12, theme: KeuTheme.from(context)),
                            DailyTable(
                              rows: state.rowsForMonth,
                              formatTanggal: state.formatTanggal,
                              formatRupiah: state.formatRupiah,
                              innerR: 12,
                              theme: KeuTheme.from(context),
                              selectedMonth: _selectedMonth,
                              isAdmin: state.isAdmin,
                              onUploadNota: (row) async {
                                final file = await pickSingleImageFile();
                                if (file == null) return;
                                if (!mounted) return; // ✅ Guard

                                try {
                                  final result = await uploadToImageKit(
                                      file: file,
                                      fileName: '${DateTime.now().millisecondsSinceEpoch}-${sanitizeForFileName(row.keterangan)}${p.extension(file.path)}',
                                      folder: '/nota',
                                      publicKey: 'public_BiPjyspsiNYuhG3VDz3DLGh1uvs=',
                                      authEndpoint: 'https://taaminmanage.netlify.app/.netlify/functions/imagekit-auth'
                                  );
                                  await FirebaseFirestore.instance.collection('keuangan').doc(row.docId).set({'notaUrl': result.url, 'notaFileId': result.fileId}, SetOptions(merge: true));
                                } catch (e) {
                                  if (!mounted) return;
                                  showAppSnackBar(this.context, 'Gagal: $e', kind: SnackKind.error);
                                }
                              },
                              onDeleteNota: (row) async {
                                await KeuFileOps.deleteImageKitIfAny(row.notaFileId);
                                await FirebaseFirestore.instance.collection('keuangan').doc(row.docId).set({'notaUrl': '', 'notaFileId': ''}, SetOptions(merge: true));
                              },
                              onDeleteRow: (row) async {
                                await KeuFileOps.deleteImageKitIfAny(row.notaFileId);
                                await FirebaseFirestore.instance.collection('keuangan').doc(row.docId).delete();
                                await FirebaseFirestore.instance.collection('notifications').add({'message': 'Transaksi ${row.keterangan} dihapus.', 'timestamp': FieldValue.serverTimestamp()});
                              },
                              onEditRow: (row) => _showUpsertTransaksiDialog(row: row),
                              onAddTransaksi: () => _showUpsertTransaksiDialog(),
                              onExportBulan: () => KeuFileOps.exportMonth(context, state.rowsForMonth, _selectedMonth),
                              onImportCsv: () => KeuFileOps.importCsv(context),
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