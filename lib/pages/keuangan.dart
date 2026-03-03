import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/pick_single_image.dart';
import '../widgets/common.dart';
import '../widgets/controls.dart';
import '../app_theme.dart';

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

class KeuanganPage extends StatefulWidget {
  const KeuanganPage({super.key});

  @override
  State<KeuanganPage> createState() => _KeuanganPageState();
}

// ---------- CSV helpers ----------

String _csvEscape(String s) {
  final needsQuotes =
      s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
  var out = s.replaceAll('"', '""');
  if (needsQuotes) out = '"$out"';
  return out;
}

String toCsv(List<List<dynamic>> rows) {
  return rows
      .map((r) => r.map((v) => _csvEscape(v?.toString() ?? '')).join(','))
      .join('\n');
}

List<List<String>> parseCsvSimple(String content) {
  final lines = content
      .split(RegExp(r'\r?\n'))
      .where((l) => l.trim().isNotEmpty)
      .toList();

  final out = <List<String>>[];

  for (final line in lines) {
    final row = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];

      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        row.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }

    row.add(buf.toString());
    out.add(row);
  }

  return out;
}

String _sanitizeForFileName(String s) {
  final trimmed = s.trim().toLowerCase();
  final replaced = trimmed.replaceAll(RegExp(r'\s+'), '-');
  return replaced.replaceAll(RegExp(r'[^a-z0-9\-_]'), '');
}

// ---------------------------------------------------------------

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

  void _setMonth(DateTime m) =>
      setState(() => _selectedMonth = DateTime(m.year, m.month));

  double _innerR() =>
      (InfoCard.radius - InfoCard.paddingAll).clamp(0.0, InfoCard.radius);

  // ---------- Add/Edit dialog ----------
  Future<void> _showUpsertTransaksiDialog({RowWithSaldo? row}) async {
    final isEdit = row != null;

    final ketC = TextEditingController(text: row?.keterangan ?? '');
    final masukC = TextEditingController(text: (row?.masuk ?? 0).toString());
    final keluarC = TextEditingController(text: (row?.keluar ?? 0).toString());
    DateTime selected = row?.tanggal ?? DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ketC,
                  decoration: const InputDecoration(labelText: 'Keterangan'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tanggal: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(selected)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked =
                        await pickDateTime(context, initial: selected);
                        if (picked != null) setState(() => selected = picked);
                      },
                      child: const Text('Ubah'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: masukC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Masuk'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keluarC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Keluar'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final newKet = ketC.text.trim();
    final newMasuk = int.tryParse(masukC.text.trim()) ?? 0;
    final newKeluar = int.tryParse(keluarC.text.trim()) ?? 0;

    final payload = {
      'keterangan': newKet,
      'tanggal': Timestamp.fromDate(selected),
      'masuk': newMasuk,
      'keluar': newKeluar,
    };

    try {
      if (isEdit) {
        await FirebaseFirestore.instance
            .collection('keuangan')
            .doc(row.docId)
            .set(payload, SetOptions(merge: true));
      } else {
        await FirebaseFirestore.instance.collection('keuangan').add(payload);
      }

      // ✅ Notification logic: Using the variable properly
      final notificationMsg = isEdit
          ? 'Transaksi $newKet sudah diubah.'
          : 'Transaksi $newKet sudah ditambahkan.';

      await FirebaseFirestore.instance.collection('notifications').add({
        'message': notificationMsg,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'keuangan_update',
      });
    } catch (e) {
      debugPrint('Error saving transaction/notification: $e');
      if (!mounted) return;
      showAppSnackBar(context, 'Gagal menyimpan: $e', kind: SnackKind.error);
    }
  }

  // ---------- Export month ----------
  Future<void> _exportMonthXlsxOrCsv(
      List<RowWithSaldo> rowsForMonth,
      DateTime selectedMonth,
      ) async {
    try {
      final filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan XLSX',
        fileName: 'transaksi-${DateFormat('yyyy-MM').format(selectedMonth)}.xlsx',
        allowedExtensions: ['xlsx'],
        type: FileType.custom,
      );
      if (filePath == null) return;

      final excel = Excel.createExcel();
      final sheet = excel['Transaksi'];

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue('keterangan');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
          .value = TextCellValue('tanggal');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
          .value = TextCellValue('masuk');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0))
          .value = TextCellValue('keluar');

      for (int i = 0; i < rowsForMonth.length; i++) {
        final r = rowsForMonth[i];
        final rowIndex = i + 1;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = TextCellValue(r.keterangan);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(
          DateFormat('yyyy-MM-dd HH:mm').format(r.tanggal),
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = IntCellValue(r.masuk);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = IntCellValue(r.keluar);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Gagal encode XLSX');

      await File(filePath).writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      showAppSnackBar(context, 'XLSX berhasil disimpan', kind: SnackKind.success);
      return;
    } catch (_) {
      // fallback to CSV logic below
    }

    final filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan CSV',
      fileName: 'transaksi-${DateFormat('yyyy-MM').format(selectedMonth)}.csv',
      allowedExtensions: ['csv'],
      type: FileType.custom,
    );
    if (filePath == null) return;

    final rows = <List<dynamic>>[
      ['keterangan', 'tanggal', 'masuk', 'keluar'],
      ...rowsForMonth.map((r) => [
        r.keterangan,
        DateFormat('yyyy-MM-dd HH:mm').format(r.tanggal),
        r.masuk,
        r.keluar,
      ]),
    ];

    final csvStr = toCsv(rows);
    await File(filePath).writeAsString(csvStr, flush: true);

    if (!mounted) return;
    showAppSnackBar(context, 'CSV berhasil disimpan');
  }

  // ---------- Import CSV ----------
  Future<void> _importCsvToKeuangan(BuildContext ctx) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;

    final bytes = res.files.single.bytes;
    if (bytes == null) {
      if (!ctx.mounted) return;
      showAppSnackBar(ctx, 'Gagal membaca file CSV', kind: SnackKind.error);
      return;
    }

    final content = utf8.decode(bytes);
    final parsed = parseCsvSimple(content);

    if (parsed.isEmpty) {
      if (!ctx.mounted) return;
      showAppSnackBar(ctx, 'CSV kosong', kind: SnackKind.error);
      return;
    }

    final header = parsed.first.map((e) => e.trim().toLowerCase()).toList();
    final kKet = header.indexOf('keterangan');
    final kTgl = header.indexOf('tanggal');
    final kMasuk = header.indexOf('masuk');
    final kKeluar = header.indexOf('keluar');

    if ([kKet, kTgl, kMasuk, kKeluar].any((i) => i < 0)) {
      if (!ctx.mounted) return;
      showAppSnackBar(ctx, 'Header CSV harus: keterangan,tanggal,masuk,keluar', kind: SnackKind.error);
      return;
    }

    final rowCount = parsed.length - 1;
    if (!ctx.mounted) return;

    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Import CSV?'),
        content: Text(
          'File berisi $rowCount baris. Ini akan MENAMBAH transaksi baru. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final col = FirebaseFirestore.instance.collection('keuangan');
    final batch = FirebaseFirestore.instance.batch();
    final maxIndex = [kKet, kTgl, kMasuk, kKeluar].reduce((a, b) => a > b ? a : b);

    int added = 0;
    for (int i = 1; i < parsed.length; i++) {
      final row = parsed[i];
      if (row.length <= maxIndex) continue;
      if (row.every((v) => v.trim().isEmpty)) continue;

      final ket = row[kKet].trim();
      final tglStr = row[kTgl].trim();

      DateTime tgl;
      try {
        tgl = DateFormat('M/d/yyyy').parseStrict(tglStr);
      } catch (_) {
        tgl = DateTime.tryParse(tglStr) ?? DateTime(1970);
      }

      final masuk = int.tryParse(row[kMasuk].trim()) ?? 0;
      final keluar = int.tryParse(row[kKeluar].trim()) ?? 0;

      final docRef = col.doc();
      batch.set(docRef, {
        'keterangan': ket,
        'tanggal': Timestamp.fromDate(tgl),
        'masuk': masuk,
        'keluar': keluar,
        'notaUrl': '',
        'notaFileId': '',
        'notaIndex': null,
        'notaFileName': '',
      });
      added++;
    }

    await batch.commit();

    if (!ctx.mounted) return;
    showAppSnackBar(ctx, 'Import selesai: $added transaksi ditambahkan', kind: SnackKind.success);
  }

  Future<void> _deleteImageKitIfAny(String fileId) async {
    if (fileId.trim().isEmpty) return;
    final resp = await http.post(
      Uri.parse('https://taaminmanage.netlify.app/.netlify/functions/imagekit-delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fileId': fileId.trim()}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Gagal hapus nota di ImageKit: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaksiStream = FirebaseFirestore.instance
        .collection('keuangan')
        .orderBy('tanggal', descending: false)
        .snapshots();

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
            final metaRef = FirebaseFirestore.instance.collection(_metaCollection).doc(_metaDocId);

            return PageScaffold(
              title: 'Keuangan',
              children: [
                const SectionTitle('Keuangan Masjid', level: 1),
                Text(
                  'Tabungan dan Deposito diupdate setiap bulan karena harus konsultasi BKK.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appColors.textColor2,
                  ),
                ),
                const SizedBox(height: 12),
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
                      final ts = data['tanggal'];
                      final tanggal = (ts is Timestamp)
                          ? ts.toDate()
                          : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime(1970);

                      baseRows.add(BaseRow(
                        docId: doc.id,
                        keterangan: (data['keterangan'] ?? '').toString(),
                        tanggal: tanggal,
                        masuk: (data['masuk'] as num?)?.toInt() ?? 0,
                        keluar: (data['keluar'] as num?)?.toInt() ?? 0,
                        notaUrl: (data['notaUrl'] ?? '').toString(),
                        notaFileId: (data['notaFileId'] ?? '').toString(),
                      ));
                    }

                    int saldo = 0;
                    final rowsChrono = <RowWithSaldo>[];
                    for (final r in baseRows) {
                      saldo = saldo + r.masuk - r.keluar;
                      rowsChrono.add(RowWithSaldo.fromBase(r, saldoKas: saldo));
                    }

                    final kasLatest = rowsChrono.isNotEmpty ? rowsChrono.last.saldoKas : 0;
                    final filteredChrono =
                    rowsChrono.where((r) => KeuHelpers.isInMonth(r.tanggal, _selectedMonth)).toList();
                    final rowsForMonth = newestFirst ? filteredChrono.reversed.toList() : filteredChrono;

                    final totalMasukBulan = filteredChrono.fold<int>(0, (s, r) => s + r.masuk);
                    final totalKeluarBulan = filteredChrono.fold<int>(0, (s, r) => s + r.keluar);
                    final diffBulan = totalMasukBulan - totalKeluarBulan;

                    final fridayAggs = KeuHelpers.computeFridayAggs(
                      year: _selectedMonth.year,
                      month: _selectedMonth.month,
                      baseRows: baseRows,
                    );

                    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: metaRef.snapshots(),
                      builder: (context, metaSnap) {
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
                            const SectionTitle("Transaksi Per Jum'at", level: 2),
                            Text(
                              'Dihitung dari Jumat lalu sampai Jumat sekarang.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.appColors.textColor2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FridayTable(
                              fridayAggs: state.fridayAggs,
                              formatRupiah: state.formatRupiah,
                              innerR: innerR,
                              theme: keuTheme,
                            ),
                            const SizedBox(height: 12),
                            const SectionTitle('Transaksi Harian', level: 2),
                            Text(
                              'Geser ke kanan untuk detail transaksi.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.appColors.textColor2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DailyTable(
                              rows: state.rowsForMonth,
                              formatTanggal: state.formatTanggal,
                              formatRupiah: state.formatRupiah,
                              innerR: innerR,
                              theme: keuTheme,
                              selectedMonth: state.selectedMonth,
                              isAdmin: state.isAdmin,
                              onUploadNota: (row) async {
                                final file = await pickSingleImageFile();
                                if (file == null) return;
                                try {
                                  final idx = DateTime.now().millisecondsSinceEpoch;
                                  final ext = p.extension(file.path);
                                  final tgl = DateFormat('yyyy-MM-dd').format(row.tanggal);
                                  final ket = _sanitizeForFileName(row.keterangan);
                                  final fileName = '$idx-$ket-$tgl$ext';

                                  final result = await uploadToImageKit(
                                    file: file,
                                    fileName: fileName,
                                    folder: '/nota',
                                    publicKey: 'public_BiPjyspsiNYuhG3VDz3DLGh1uvs=',
                                    authEndpoint:
                                    'https://taaminmanage.netlify.app/.netlify/functions/imagekit-auth',
                                  );

                                  await FirebaseFirestore.instance
                                      .collection('keuangan')
                                      .doc(row.docId)
                                      .set({
                                    'notaUrl': result.url,
                                    'notaFileId': result.fileId ?? '',
                                    'notaIndex': idx,
                                    'notaFileName': fileName,
                                  }, SetOptions(merge: true));
                                } catch (e) {
                                  if (!mounted) return;
                                  showAppSnackBar(context, 'Upload gagal: $e', kind: SnackKind.error);
                                }
                              },
                              onDeleteNota: (row) async {
                                try {
                                  await _deleteImageKitIfAny(row.notaFileId);
                                  await FirebaseFirestore.instance
                                      .collection('keuangan')
                                      .doc(row.docId)
                                      .set({
                                    'notaUrl': '',
                                    'notaFileId': '',
                                    'notaIndex': null,
                                    'notaFileName': '',
                                  }, SetOptions(merge: true));
                                } catch (e) {
                                  if (!mounted) return;
                                  showAppSnackBar(context, 'Hapus gagal: $e', kind: SnackKind.error);
                                }
                              },
                              onEditRow: (row) => _showUpsertTransaksiDialog(row: row),
                              onDeleteRow: (row) async {
                                final ket = row.keterangan.trim();

                                try {
                                  // delete nota first (if any)
                                  await _deleteImageKitIfAny(row.notaFileId);

                                  // delete transaksi
                                  await FirebaseFirestore.instance.collection('keuangan').doc(row.docId).delete();

                                  // add notification (so MainShell listener shows it)
                                  final notificationMsg =
                                  ket.isEmpty ? 'Transaksi sudah dihapus.' : 'Transaksi $ket sudah dihapus.';

                                  await FirebaseFirestore.instance.collection('notifications').add({
                                    'message': notificationMsg,
                                    'timestamp': FieldValue.serverTimestamp(),
                                    'type': 'keuangan_delete',
                                  });

                                  if (!mounted) return;
                                  showAppSnackBar(context, notificationMsg, kind: SnackKind.success);
                                } catch (e) {
                                  if (!mounted) return;
                                  showAppSnackBar(context, 'Gagal menghapus: $e', kind: SnackKind.error);
                                }
                              },
                              onAddTransaksi: () => _showUpsertTransaksiDialog(),
                              onExportBulan: () =>
                                  _exportMonthXlsxOrCsv(state.rowsForMonth, state.selectedMonth),
                              onImportCsv: () => _importCsvToKeuangan(context),
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