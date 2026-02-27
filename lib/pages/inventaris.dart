import 'package:flutter/material.dart';
import '../widgets/common.dart';

class InventarisPage extends StatelessWidget {
  const InventarisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Inventaris',
      children: [
        const SectionTitle('Daftar Barang (mockup)'),
        const InfoCard(
          child: Column(
            children: [
              _InventoryItem(name: 'Karpet sholat', detail: '12 roll • Kondisi: Baik'),
              Divider(),
              _InventoryItem(name: 'Speaker aktif', detail: '2 unit • Kondisi: Baik'),
              Divider(),
              _InventoryItem(name: 'Mikrofon', detail: '4 unit • Kondisi: Perlu servis'),
              Divider(),
              _InventoryItem(name: 'Kipas angin', detail: '6 unit • Kondisi: Baik'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionTitle('Catatan Perawatan'),
        const InfoCard(
          child: BulletItem(
            title: 'Servis mikrofon 2 unit',
            subtitle: 'Target minggu ini (mockup).',
          ),
        ),
      ],
    );
  }
}

class _InventoryItem extends StatelessWidget {
  final String name;
  final String detail;
  const _InventoryItem({required this.name, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_box_outline_blank),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(detail),
            ],
          ),
        ),
        const Icon(Icons.more_vert),
      ],
    );
  }
}