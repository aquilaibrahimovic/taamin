import 'package:flutter/material.dart';
import '../widgets/common.dart';

class InformasiPage extends StatelessWidget {
  const InformasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Informasi',
      children: [
        const SectionTitle('Pengumuman'),
        const InfoCard(
          child: Column(
            children: [
              ListTileMock(
                icon: Icons.campaign,
                title: 'Informasi Zakat Fitrah',
                subtitle: 'Ketentuan & jadwal penerimaan (mockup).',
              ),
              Divider(),
              ListTileMock(
                icon: Icons.event,
                title: 'Agenda Ramadhan',
                subtitle: 'Tarawih, tadarus, iftar (mockup).',
              ),
              Divider(),
              ListTileMock(
                icon: Icons.groups,
                title: 'Kegiatan Remaja Masjid',
                subtitle: 'Jadwal latihan hadroh (mockup).',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionTitle('Kontak & Lokasi'),
        const InfoCard(
          child: Column(
            children: [
              RowItem(left: 'Takmir', right: '08xx-xxxx-xxxx'),
              Divider(),
              RowItem(left: 'Email', right: 'masjid@example.com'),
              Divider(),
              RowItem(left: 'Alamat', right: 'Jl. Contoh No. 123'),
            ],
          ),
        ),
      ],
    );
  }
}