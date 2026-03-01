import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';

class ToggleSegment<T> {
  final T value;
  final String label;
  final IconData? icon;

  const ToggleSegment({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Full-width segmented toggle with equal-width segments (2, 3, 4...).
/// Single-select API: `selected: T` and `onChanged(T)`.
class FullWidthSegmentedToggle<T> extends StatelessWidget {
  final List<ToggleSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Show icons (when provided).
  final bool showIcons;

  /// Optional: make the control a little more compact/tall.
  final VisualDensity? visualDensity;

  final bool showSelectedIcon;

  const FullWidthSegmentedToggle({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.showIcons = true,
    this.visualDensity,
    this.showSelectedIcon = false,
  }) : assert(segments.length >= 2, 'Need at least 2 segments.');

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    // Unified design tokens
    final borderRadius = BorderRadius.circular(14);
    final outline = BorderSide(color: Theme.of(context).dividerColor);
    final selectedBg = c.accent2a.withAlpha(64);

    final style = ButtonStyle(
      visualDensity: visualDensity,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      side: WidgetStatePropertyAll(outline),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return selectedBg;
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Theme.of(context).disabledColor;
        }
        return Theme.of(context).textTheme.bodyMedium?.color;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return selectedBg.withAlpha(40);
        }
        if (states.contains(WidgetState.hovered)) {
          return selectedBg.withAlpha(24);
        }
        return null;
      }),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = segments.length;
        final segmentWidth = constraints.maxWidth / count;

        return SegmentedButton<T>(
          showSelectedIcon: showSelectedIcon,
          style: style,
          segments: [
            for (final s in segments)
              ButtonSegment<T>(
                value: s.value,
                label: SizedBox(
                  width: segmentWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showIcons && s.icon != null) ...[
                        Icon(s.icon, size: 18),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          s.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          selected: {selected},
          onSelectionChanged: (set) => onChanged(set.first),
        );
      },
    );
  }
}

/// Opens a month+year picker dialog and returns the chosen month (DateTime(year, month)).
Future<DateTime?> pickMonthYear(
    BuildContext context, {
      required DateTime initialMonth,
      String locale = 'id_ID',
      int yearBack = 10,
      int yearForward = 10,
    }) async {
  final now = DateTime.now();
  int selectedYear = initialMonth.year;
  int selectedMonth = initialMonth.month;

  final monthFmt = DateFormat('MMMM', locale);
  final months = List.generate(
    12,
        (i) => monthFmt.format(DateTime(2000, i + 1, 1)),
  );

  final years = List.generate(
    yearBack + yearForward + 1,
        (i) => (now.year - yearBack) + i,
  );

  return showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Pilih Bulan & Tahun'),
        content: StatefulBuilder(
          builder: (ctx, setState) {
            return SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: selectedYear,
                    isExpanded: true,
                    items: years
                        .map(
                          (y) => DropdownMenuItem<int>(
                        value: y,
                        child: Text(y.toString()),
                      ),
                    )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => selectedYear = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    itemCount: 12,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.4,
                    ),
                    itemBuilder: (ctx, i) {
                      final c = Theme.of(context).colorScheme;
                      final m = i + 1;
                      final isSelected = m == selectedMonth;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => selectedMonth = m),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? c.primary
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            months[i],
                            overflow: TextOverflow.ellipsis,
                            style: isSelected
                                ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.primary,
                            )
                                : Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, DateTime(selectedYear, selectedMonth)),
            child: const Text('Pilih'),
          ),
        ],
      );
    },
  );
}

Future<DateTime?> pickDateTime(
    BuildContext context, {
      required DateTime initial,
      String locale = 'id_ID',
    }) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    locale: Locale(locale.split('_').first, locale.split('_').last),
  );
  if (date == null) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}

/// A reusable month switcher:  < Februari 2026 >
/// Styled to match the segmented toggle outline + subtle fill.
class MonthSwitcher extends StatelessWidget {
  final DateTime selectedMonth; // should be DateTime(year, month)
  final ValueChanged<DateTime> onChanged;
  final String locale;

  const MonthSwitcher({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
    this.locale = 'id_ID',
  });

  DateTime _prevMonth(DateTime d) => DateTime(d.year, d.month - 1);
  DateTime _nextMonth(DateTime d) => DateTime(d.year, d.month + 1);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final label = DateFormat('MMMM y', locale).format(selectedMonth);

    final borderRadius = BorderRadius.circular(14);
    final outline = BorderSide(color: Theme.of(context).dividerColor);
    final fill = c.accent2a.withAlpha(32); // subtle, matches toggle family

    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.fromBorderSide(outline),
        color: fill,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan sebelumnya',
            onPressed: () => onChanged(_prevMonth(selectedMonth)),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: InkWell(
              borderRadius: borderRadius,
              onTap: () async {
                final picked = await pickMonthYear(
                  context,
                  initialMonth: selectedMonth,
                  locale: locale,
                );
                if (picked != null) {
                  onChanged(DateTime(picked.year, picked.month));
                }
              },
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            onPressed: () => onChanged(_nextMonth(selectedMonth)),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class TinyIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  const TinyIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      visualDensity: VisualDensity.compact,
    );
  }
}