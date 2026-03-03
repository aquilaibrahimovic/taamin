import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../widgets/controls.dart';
import '../app_theme.dart';
import '../settings.dart';

final auth = FirebaseAuth.instance;
final adminDoc = FirebaseFirestore.instance.collection('config').doc('admins');

class AkunPage extends StatelessWidget {
  const AkunPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Akun',
      children: [
        InfoCard(
          child: StreamBuilder<User?>(
            stream: auth.authStateChanges(),
            builder: (context, userSnap) {
              final user = userSnap.data;

              if (user == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Admin', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Login Admin'),
                      onPressed: () async {
                        final usernameCtrl = TextEditingController();
                        final passCtrl = TextEditingController();

                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Login Admin'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: usernameCtrl,
                                  decoration: const InputDecoration(labelText: 'Username'),
                                  textInputAction: TextInputAction.next,
                                ),
                                TextField(
                                  controller: passCtrl,
                                  obscureText: true,
                                  decoration: const InputDecoration(labelText: 'Password'),
                                  textInputAction: TextInputAction.done,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Login'),
                              ),
                            ],
                          ),
                        );

                        final username = usernameCtrl.text.trim();
                        final password = passCtrl.text;

                        // cleanup
                        usernameCtrl.dispose();
                        passCtrl.dispose();

                        if (ok != true) return;

                        if (username.isEmpty || password.isEmpty) {
                          showAppSnackBar(context, 'Username dan password wajib diisi', kind: SnackKind.error);
                          return;
                        }

                        final email = '$username@taamin.local';

                        try {
                          await auth.signInWithEmailAndPassword(email: email, password: password);
                          showAppSnackBar(context, 'Login berhasil', kind: SnackKind.success);
                        } on FirebaseAuthException catch (e) {
                          showAppSnackBar(context, 'Login gagal: ...', kind: SnackKind.error);
                        } catch (e) {
                          showAppSnackBar(context, 'Login gagal: ...', kind: SnackKind.error);
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gunakan akun admin untuk mengubah Tabungan & Deposito.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appColors.textColor2,
                      ),
                    ),
                  ],
                );
              }

              // Logged in: show whether this user is admin based on config/admins.emails
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: adminDoc.snapshots(),
                builder: (context, adminSnap) {
                  final data = adminSnap.data?.data() ?? const <String, dynamic>{};
                  final emails = (data['emails'] as Map?)?.cast<String, dynamic>() ?? const {};
                  final isAdmin = emails[user.email] == true;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Admin', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(user.email ?? '-', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Chip(
                            label: Text(isAdmin ? 'ADMIN' : 'Bukan admin'),
                            avatar: Icon(isAdmin ? Icons.verified : Icons.info_outline),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            onPressed: () => auth.signOut(),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
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