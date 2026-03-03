import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'keu_csv.dart';
import 'keu_models.dart';
import '../../widgets/common.dart';

class KeuFileOps {
  /// ✅ Deletes a file from ImageKit via Netlify function
  static Future<void> deleteImageKitIfAny(String fileId) async {
    if (fileId.trim().isEmpty) return;
    final resp = await http.post(
      Uri.parse('https://taaminmanage.netlify.app/.netlify/functions/imagekit-delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fileId': fileId.trim()}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Gagal hapus di ImageKit: ${resp.statusCode}');
    }
  }

  /// ✅ Standard Export logic (XLSX with CSV fallback)
  static Future<void> exportMonth(BuildContext context, List<RowWithSaldo> rows, DateTime month) async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan XLSX',
        fileName: 'transaksi-${DateFormat('yyyy-MM').format(month)}.xlsx',
        allowedExtensions: ['xlsx'],
        type: FileType.custom,
      );
      if (path == null) return;
      if (!context.mounted) return;

      final excel = Excel.createExcel();
      final sheet = excel['Transaksi'];

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('keterangan');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('tanggal');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = TextCellValue('masuk');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue('keluar');

      for (int i = 0; i < rows.length; i++) {
        final r = rows[i];
        final rowIndex = i + 1;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(r.keterangan);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(r.tanggal));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = IntCellValue(r.masuk);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = IntCellValue(r.keluar);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Gagal encode XLSX');
      await File(path).writeAsBytes(bytes, flush: true);

      if (!context.mounted) return; // ✅ Guarding context after async gap
      showAppSnackBar(context, 'XLSX berhasil disimpan', kind: SnackKind.success);
    } catch (_) {
      // Fallback to CSV
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan CSV',
        fileName: 'transaksi-${DateFormat('yyyy-MM').format(month)}.csv',
        allowedExtensions: ['csv'],
        type: FileType.custom,
      );
      if (path == null) return;
      if (!context.mounted) return;

      final csvData = <List<dynamic>>[
        ['keterangan', 'tanggal', 'masuk', 'keluar'],
        ...rows.map((r) => [r.keterangan, DateFormat('yyyy-MM-dd HH:mm').format(r.tanggal), r.masuk, r.keluar]),
      ];
      await File(path).writeAsString(toCsv(csvData), flush: true);
      if (!context.mounted) return; // ✅ Guarding context after async gap
      showAppSnackBar(context, 'CSV berhasil disimpan');
    }
  }

  /// ✅ Standard Import logic
  static Future<void> importCsv(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    if (res == null || res.files.isEmpty) return;
    if (!context.mounted) return;

    final bytes = res.files.single.bytes;
    if (bytes == null) return;

    final content = utf8.decode(bytes);
    final parsed = parseCsvSimple(content);
    if (parsed.isEmpty) return;

    final header = parsed.first.map((e) => e.trim().toLowerCase()).toList();
    final kKet = header.indexOf('keterangan');
    final kTgl = header.indexOf('tanggal');
    final kMasuk = header.indexOf('masuk');
    final kKeluar = header.indexOf('keluar');

    if ([kKet, kTgl, kMasuk, kKeluar].any((i) => i < 0)) {
      if (context.mounted) showAppSnackBar(context, 'Header CSV salah', kind: SnackKind.error);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import CSV?'),
        content: Text('Akan menambah ${parsed.length - 1} transaksi baru. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;

    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance.collection('keuangan');

    for (int i = 1; i < parsed.length; i++) {
      final row = parsed[i];
      final tglStr = row[kTgl].trim();
      DateTime tgl = DateTime.tryParse(tglStr) ?? DateTime(1970);

      batch.set(col.doc(), {
        'keterangan': row[kKet].trim(),
        'tanggal': Timestamp.fromDate(tgl),
        'masuk': int.tryParse(row[kMasuk].trim()) ?? 0,
        'keluar': int.tryParse(row[kKeluar].trim()) ?? 0,
      });
    }

    await batch.commit();
    if (!context.mounted) return; // ✅ Guarding context after batch commit
    showAppSnackBar(context, 'Import selesai', kind: SnackKind.success);
  }
}