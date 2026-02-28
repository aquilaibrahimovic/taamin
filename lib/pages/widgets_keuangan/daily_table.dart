import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/common.dart';
import 'keu_models.dart';
import 'keu_theme.dart';

class DailyTable extends StatelessWidget {
  final List<RowWithSaldo> rows;
  final String Function(DateTime) formatTanggal;
  final String Function(num) formatRupiah;

  final double innerR;
  final KeuTheme theme;

  final DateTime selectedMonth;

  const DailyTable({
    super.key,
    required this.rows,
    required this.formatTanggal,
    required this.formatRupiah,
    required this.innerR,
    required this.theme,
    required this.selectedMonth,
  });

  static const double colKet = 150;
  static const double colTanggal = 170;
  static const double colMasuk = 170;
  static const double colKeluar = 170;
  static const double colSaldo = 150;
  static const double colNota = 90;
  static const double rowH = 52;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const InfoCard(child: Text('Tidak ada transaksi pada bulan ini.'));
    }

    // ✅ month totals from currently displayed rows (your selected month)
    final totalMasuk = rows.fold<int>(0, (s, r) => s + r.masuk);
    final totalKeluar = rows.fold<int>(0, (s, r) => s + r.keluar);

    final hController = ScrollController();
    final dividerColor = Theme.of(context).dividerColor;

    final monoNumStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final monoNumBold = monoNumStyle?.copyWith(fontWeight: FontWeight.w800);

    Color ketBg(int i) => (i % 2 == 0) ? theme.ketRowEven : theme.ketRowOdd;
    Color rowBg(int i) => (i % 2 == 0) ? theme.accentRowEven : theme.accentRowOdd;

    // ✅ total row background (a bit stronger)
    final totalBg = Color.alphaBlend(
      Colors.black.withAlpha(18),
      theme.accentRowEven,
    );

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
          BoxBorder? border,
        }) {
      return Container(
        width: w,
        height: rowH,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: align,
        decoration: BoxDecoration(
          color: bgColor,
          border: border,
        ),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      );
    }

    final rightWidth = colTanggal + colMasuk + colKeluar + colSaldo + colNota;

    return InfoCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerR),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column (Keterangan)
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
                      bgColor: ketBg(i),
                    );
                  }),

                  // ✅ TOTAL row (left)
                  dataCell(
                    'TOTAL',
                    w: colKet,
                    bgColor: totalBg,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                    border: Border(top: BorderSide(color: dividerColor)),
                  ),
                ],
              ),
            ),

            // Right scrollable columns
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
                        // Header row
                        Row(
                          children: [
                            headerCell('Tanggal', w: colTanggal),
                            headerCell('Masuk',
                                w: colMasuk, align: Alignment.centerRight),
                            headerCell('Keluar',
                                w: colKeluar, align: Alignment.centerRight),
                            headerCell('Saldo Kas',
                                w: colSaldo, align: Alignment.centerRight),
                            headerCell('Nota', w: colNota),
                          ],
                        ),

                        // Data rows
                        ...List.generate(rows.length, (i) {
                          final r = rows[i];
                          final bg = rowBg(i);

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
                                style: monoNumStyle?.copyWith(color: theme.yesColor),
                              ),
                              dataCell(
                                formatRupiah(r.keluar),
                                w: colKeluar,
                                align: Alignment.centerRight,
                                bgColor: bg,
                                style: monoNumStyle?.copyWith(color: theme.noColor),
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
                                  onPressed: r.notaUrl.isNotEmpty ? () {/* TODO */} : null,
                                  child: const Text('Lihat'),
                                ),
                              ),
                            ],
                          );
                        }),

                        // ✅ TOTAL row (right)
                        Row(
                          children: [
                            dataCell(
                              DateFormat('MMMM y', 'id_ID').format(selectedMonth),
                              w: colTanggal,
                              bgColor: totalBg,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              border: Border(top: BorderSide(color: dividerColor)),
                            ),
                            dataCell(
                              formatRupiah(totalMasuk),
                              w: colMasuk,
                              align: Alignment.centerRight,
                              bgColor: totalBg,
                              style: monoNumBold?.copyWith(color: theme.yesColor),
                              border: Border(top: BorderSide(color: dividerColor)),
                            ),
                            dataCell(
                              formatRupiah(totalKeluar),
                              w: colKeluar,
                              align: Alignment.centerRight,
                              bgColor: totalBg,
                              style: monoNumBold?.copyWith(color: theme.noColor),
                              border: Border(top: BorderSide(color: dividerColor)),
                            ),
                            dataCell(
                              '-', // saldo total for month doesn't make sense here
                              w: colSaldo,
                              align: Alignment.centerRight,
                              bgColor: totalBg,
                              style: monoNumBold,
                              border: Border(top: BorderSide(color: dividerColor)),
                            ),
                            Container(
                              width: colNota,
                              height: rowH,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: totalBg,
                                border: Border(top: BorderSide(color: dividerColor)),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}