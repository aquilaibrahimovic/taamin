import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/common.dart';
import 'keu_theme.dart';

class MonthlyEval extends StatelessWidget {
  final DateTime selectedMonth;
  final int totalMasukBulan;
  final int totalKeluarBulan;
  final int diffBulan;
  final String Function(num) formatRupiah;

  final double innerR;
  final KeuTheme theme;

  const MonthlyEval({
    super.key,
    required this.selectedMonth,
    required this.totalMasukBulan,
    required this.totalKeluarBulan,
    required this.diffBulan,
    required this.formatRupiah,
    required this.innerR,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerR),
        child: Padding(
          padding: const EdgeInsets.all(InfoCard.paddingAll),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Neraca Bulan ${DateFormat('MMMM y', 'id_ID').format(selectedMonth)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),

              Center(
                child: _DonutChart(
                  masuk: totalMasukBulan,
                  keluar: totalKeluarBulan,
                  masukColor: theme.yesColor,
                  keluarColor: theme.noColor,
                  centerTextColor: theme.textColor2,
                ),
              ),

              const SizedBox(height: 14),

              _LegendRow(
                dotColor: theme.yesColor,
                title: 'Pemasukan',
                value: formatRupiah(totalMasukBulan),
              ),
              const SizedBox(height: 10),
              _LegendRow(
                dotColor: theme.noColor,
                title: 'Pengeluaran',
                value: formatRupiah(totalKeluarBulan),
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      diffBulan >= 0 ? 'Surplus' : 'Defisit',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatRupiah(diffBulan.abs()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: diffBulan >= 0 ? theme.yesColor : theme.noColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- donut classes stay same as before (no changes) ----

class _DonutChart extends StatelessWidget {
  final int masuk;
  final int keluar;
  final Color masukColor;
  final Color keluarColor;
  final Color centerTextColor;

  const _DonutChart({
    required this.masuk,
    required this.keluar,
    required this.masukColor,
    required this.keluarColor,
    required this.centerTextColor,
  });

  static const double _size = 170;
  static const double _stroke = 18;

  @override
  Widget build(BuildContext context) {
    final diff = masuk - keluar;

    final jutaFmt = NumberFormat('0.0', 'id_ID');
    final absJuta = (diff.abs() / 1000000.0);
    final jutaText = jutaFmt.format(absJuta);

    final isSurplus = diff >= 0;
    final diffColor = isSurplus ? masukColor : keluarColor;
    final chevron = isSurplus ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(_size, _size),
            painter: _DonutPainter(
              masuk: masuk,
              keluar: keluar,
              masukColor: masukColor,
              keluarColor: keluarColor,
              stroke: _stroke,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                jutaText,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 20) * 2,
                  fontWeight: FontWeight.w800,
                  color: diffColor,
                  fontFamily: 'monospace',
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chevron, size: 18, color: diffColor),
                  const SizedBox(width: 4),
                  Text(
                    'Juta',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: centerTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int masuk;
  final int keluar;
  final Color masukColor;
  final Color keluarColor;
  final double stroke;

  _DonutPainter({
    required this.masuk,
    required this.keluar,
    required this.masukColor,
    required this.keluarColor,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = masuk + keluar;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - stroke / 2;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = Colors.white.withAlpha(20);

    canvas.drawCircle(center, radius, basePaint);
    if (total <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -3.1415926535 / 2;

    final masukSweep = (masuk / total) * (2 * 3.1415926535);
    final keluarSweep = (keluar / total) * (2 * 3.1415926535);

    final masukPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = masukColor;

    final keluarPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = keluarColor;

    canvas.drawArc(rect, startAngle, masukSweep, false, masukPaint);
    canvas.drawArc(rect, startAngle + masukSweep, keluarSweep, false, keluarPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.masuk != masuk ||
        oldDelegate.keluar != keluar ||
        oldDelegate.masukColor != masukColor ||
        oldDelegate.keluarColor != keluarColor ||
        oldDelegate.stroke != stroke;
  }
}

class _LegendRow extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String value;

  const _LegendRow({
    required this.dotColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, overflow: TextOverflow.ellipsis),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}