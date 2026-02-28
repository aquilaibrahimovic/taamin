import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import 'keu_models.dart';
import 'keu_theme.dart';

class DailyTable extends StatelessWidget {
  final List<RowWithSaldo> rows;
  final String Function(DateTime) formatTanggal;
  final String Function(num) formatRupiah;

  final double innerR;
  final KeuTheme theme;

  const DailyTable({
    super.key,
    required this.rows,
    required this.formatTanggal,
    required this.formatRupiah,
    required this.innerR,
    required this.theme,
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

    final hController = ScrollController();
    final dividerColor = Theme.of(context).dividerColor;

    final monoNumStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Color ketBg(int i) => (i % 2 == 0) ? theme.ketRowEven : theme.ketRowOdd;
    Color rowBg(int i) => (i % 2 == 0) ? theme.accentRowEven : theme.accentRowOdd;

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
        decoration: BoxDecoration(color: bgColor),
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
                ],
              ),
            ),
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
                            headerCell('Masuk', w: colMasuk, align: Alignment.centerRight),
                            headerCell('Keluar', w: colKeluar, align: Alignment.centerRight),
                            headerCell('Saldo Kas', w: colSaldo, align: Alignment.centerRight),
                            headerCell('Nota', w: colNota),
                          ],
                        ),
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