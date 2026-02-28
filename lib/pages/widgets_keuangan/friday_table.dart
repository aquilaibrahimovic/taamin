import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/common.dart';
import 'keu_models.dart';
import 'keu_theme.dart';

class FridayTable extends StatelessWidget {
  final List<FridayAgg> fridayAggs;
  final String Function(num) formatRupiah;

  final double innerR;
  final KeuTheme theme;

  const FridayTable({
    super.key,
    required this.fridayAggs,
    required this.formatRupiah,
    required this.innerR,
    required this.theme,
  });

  static const double rowH = 52;
  static const double colJumatIdx = 160;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor;

    final monoNumStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
    );

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

    return InfoCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerR),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                headerCell("Jum'at", w: colJumatIdx, align: Alignment.center),
                Expanded(
                  child: Container(
                    height: rowH,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: dividerColor)),
                    ),
                    child: Text(
                      'Neraca',
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),

            ...List.generate(5, (i) {
              final agg = fridayAggs[i];
              final bg = rowBg(i);

              final jumatText = agg.exists ? '${i + 1}' : '-';
              final masukText = agg.exists ? formatRupiah(agg.masuk) : '-';
              final keluarText = agg.exists
                  ? 'Rp. -${NumberFormat.decimalPattern('id_ID').format(agg.keluar)}'
                  : '-';

              return Row(
                children: [
                  dataCell(
                    jumatText,
                    w: colJumatIdx,
                    align: Alignment.center,
                    bgColor: bg,
                    style: monoNumStyle,
                  ),
                  Expanded(
                    child: Container(
                      height: rowH,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: bg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            masukText,
                            textAlign: TextAlign.right,
                            style: agg.exists
                                ? monoNumStyle?.copyWith(color: theme.yesColor)
                                : monoNumStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            keluarText,
                            textAlign: TextAlign.right,
                            style: agg.exists
                                ? monoNumStyle?.copyWith(color: theme.noColor)
                                : monoNumStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}