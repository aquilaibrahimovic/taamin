import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../app_theme.dart';
import '../ui_elements.dart';
import '../settings.dart';

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
        const SectionTitle('Tampilan'),
        InfoCard(
          child: _ThemeModeToggle(),
        ),
        InfoCard(
          child: _TextSizeToggle(),
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
    final settings = SettingsScope.of(context);

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
          selected: settings.themeMode,
          onChanged: (mode) => settings.setThemeMode(mode),
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

class _TextSizeToggle extends StatelessWidget {
  const _TextSizeToggle();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);

    final selected = settings.textScale >= 1.25 ? FontSizeChoice.besar : FontSizeChoice.sedang;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ukuran huruf', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        FullWidthSegmentedToggle<FontSizeChoice>(
          segments: const [
            ToggleSegment(value: FontSizeChoice.sedang, label: 'Sedang', icon: Icons.text_fields),
            ToggleSegment(value: FontSizeChoice.besar, label: 'Besar', icon: Icons.format_size),
          ],
          selected: selected,
          onChanged: (choice) {
            settings.setTextScale(choice == FontSizeChoice.sedang ? 1.0 : 1.5);
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Sedang = normal, Besar = 1.5x.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.appColors.textColor2,
          ),
        ),
      ],
    );
  }
}

enum FontSizeChoice { sedang, besar }