import 'package:flutter/material.dart';
import '../app_theme.dart';

enum SnackKind { info, success, error }

void showAppSnackBar(
    BuildContext context,
    String message, {
      SnackKind kind = SnackKind.info,
      IconData? icon,
      Duration duration = const Duration(seconds: 4),
    }) {
  final messenger = ScaffoldMessenger.of(context);

  final bg = switch (kind) {
    SnackKind.error => context.appColors.noColor,
    SnackKind.success => context.appColors.yesColor,
    SnackKind.info => context.appColors.yesColor, // you can change this later if you add an "infoColor"
  };

  final defaultIcon = switch (kind) {
    SnackKind.error => Icons.error_outline,
    SnackKind.success => Icons.check_circle_outline,
    SnackKind.info => Icons.info_outline,
  };

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.fixed,
      backgroundColor: bg,
      duration: duration,
      content: Row(
        children: [
          Icon(icon ?? defaultIcon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class PageScaffold extends StatelessWidget {
  final String title; // you can keep this for now (unused), or remove later
  final List<Widget> children;

  const PageScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          // ✅ keeps content below the status bar + your existing 16px padding
          padding: EdgeInsets.fromLTRB(16, 16 + topInset, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate(children),
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;

  /// 1 = top-level section, 2 = subsection, 3 = minor label
  final int level;

  const SectionTitle(this.text, {super.key, this.level = 1});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    final style = switch (level) {
      1 => theme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      2 => theme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      _ => theme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    };

    // More spacing for higher levels
    final top = switch (level) {
      1 => 16.0,
      2 => 14.0,
      _ => 10.0,
    };
    final bottom = switch (level) {
      1 => 10.0,
      2 => 8.0,
      _ => 6.0,
    };

    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Text(text, style: style),
    );
  }
}

class InfoCard extends StatelessWidget {
  static const double paddingAll = 14.0;
  static const double radius = 24.0;

  final Widget child;
  const InfoCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(paddingAll),
        child: child,
      ),
    );
  }
}

/* ---- Small reusable building blocks ---- */

class RowItem extends StatelessWidget {
  final String left;
  final String right;
  const RowItem({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(left)),
        Text(
          right,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

class BulletItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const BulletItem({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.circle, size: 10),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class ListTileMock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ListTileMock({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}