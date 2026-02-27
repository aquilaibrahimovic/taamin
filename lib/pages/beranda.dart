import 'package:flutter/material.dart';
import '../widgets/common.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Beranda',
      children: [
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masjid Raudlatus Sholihin',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Ringkasan hari ini (mockup)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _StatChip(label: 'Pengumuman', value: '2'),
                  _StatChip(label: 'Agenda', value: '1'),
                  _StatChip(label: 'Kas Bulan Ini', value: 'Rp 3.2 jt'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionTitle('Jadwal Sholat (mockup)'),
        const InfoCard(
          child: Column(
            children: [
              RowItem(left: 'Subuh', right: '04:35'),
              Divider(),
              RowItem(left: 'Dzuhur', right: '12:05'),
              Divider(),
              RowItem(left: 'Ashar', right: '15:25'),
              Divider(),
              RowItem(left: 'Maghrib', right: '18:10'),
              Divider(),
              RowItem(left: 'Isya', right: '19:20'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionTitle('Pengumuman Terbaru'),
        const InfoCard(
          child: Column(
            children: [
              BulletItem(
                title: 'Kerja bakti masjid',
                subtitle: 'Ahad, 07.00 WIB — mohon partisipasi jamaah.',
              ),
              Divider(),
              BulletItem(
                title: 'Kajian rutin',
                subtitle: 'Jumat ba’da Isya — tema: adab bertetangga.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}