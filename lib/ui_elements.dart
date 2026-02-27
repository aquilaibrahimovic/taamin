import 'package:flutter/material.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = segments.length;
        final segmentWidth = constraints.maxWidth / count;

        return SegmentedButton<T>(
          showSelectedIcon: showSelectedIcon,
          style: ButtonStyle(
            visualDensity: visualDensity,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
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