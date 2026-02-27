import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../app_theme.dart';
import '../ui_elements.dart';

class AkunPage extends StatelessWidget {
  const AkunPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Akun',
      children: [
        InfoCard(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                child: Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Masjid', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('admin@masjid.com (mockup)'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionTitle('Tema'),
        InfoCard(
          child: _ThemeModeToggle(),
        ),
        const SizedBox(height: 12),
        const SectionTitle('Pengaturan'),
        const InfoCard(
          child: Column(
            children: [
              ListTileMock(
                icon: Icons.edit,
                title: 'Ubah Profil',
                subtitle: 'Nama, kontak, dll (mockup).',
              ),
              Divider(),
              ListTileMock(
                icon: Icons.lock,
                title: 'Keamanan',
                subtitle: 'Ubah PIN / password (mockup).',
              ),
              Divider(),
              ListTileMock(
                icon: Icons.logout,
                title: 'Keluar',
                subtitle: 'Logout akun (mockup).',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeModeToggle extends StatelessWidget {
  const _ThemeModeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode tampilan',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),

        // ✅ Full-width, equal segments (from ui_elements.dart)
        FullWidthSegmentedToggle<ThemeMode>(
          segments: const [
            ToggleSegment(
              value: ThemeMode.light,
              label: 'Terang',
              icon: Icons.light_mode_outlined,
            ),
            ToggleSegment(
              value: ThemeMode.system,
              label: 'Sistem',
              icon: Icons.settings_outlined,
            ),
            ToggleSegment(
              value: ThemeMode.dark,
              label: 'Gelap',
              icon: Icons.dark_mode_outlined,
            ),
          ],
          selected: controller.mode,
          onChanged: controller.setMode,
        ),

        const SizedBox(height: 6),
        Text(
          'Default: mengikuti tema perangkat.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.appColors.textColor2,
          ),
        ),
      ],
    );
  }
}