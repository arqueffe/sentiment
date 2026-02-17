import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'package:sentiment/models/emotion.dart';
import 'package:sentiment/models/entry.dart';
import 'package:sentiment/state/providers.dart';
import 'package:sentiment/ui/insights/insights_metrics.dart';
import 'package:sentiment/ui/widgets/emotion_color.dart';
import 'package:sentiment/ui/widgets/settings_button.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

enum _InsightsWindow {
  week('7D', 7),
  month('30D', 30),
  quarter('90D', 90),
  all('All', null);

  const _InsightsWindow(this.label, this.days);

  final String label;
  final int? days;
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  _InsightsWindow _window = _InsightsWindow.month;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 24, width: 24),
            const SizedBox(width: 8),
            const Text('Insights'),
          ],
        ),
        actions: const [SettingsButton()],
      ),
      body: entries.when(
        data: (items) {
          final filteredItems = _applyWindow(items, _window);
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          if (filteredItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      size: 44,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No data in this time window',
                      style: textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final metrics = buildInsightsMetrics(filteredItems);
          final uniqueDays = filteredItems
              .map(
                (entry) => DateTime(
                  entry.createdAt.year,
                  entry.createdAt.month,
                  entry.createdAt.day,
                ),
              )
              .toSet();
          final sortedByDate = [...filteredItems]
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          final windowRange = sortedByDate.isEmpty
              ? ''
              : '${DateFormat.MMMd().format(sortedByDate.first.createdAt)} - ${DateFormat.MMMd().format(sortedByDate.last.createdAt)}';
          final streak = _currentEntryStreak(filteredItems);
          final topMoodEntry = metrics.moodSorted.isEmpty
              ? null
              : metrics.moodSorted.first;
          final topMoodLabel = topMoodEntry == null
              ? '—'
              : (EmotionCatalog.byId(topMoodEntry.key)?.label ??
                    topMoodEntry.key);
          final topMoodShare =
              topMoodEntry == null || metrics.totalMoodSamples == 0
              ? 0
              : ((topMoodEntry.value / metrics.totalMoodSamples) * 100).round();
          final consistency =
              ((metrics.preCount + metrics.postCount) /
                      (filteredItems.length * 2) *
                      100)
                  .round();
          final busiestWeekday = _busiestWeekday(filteredItems);
          final avgEntries =
              (filteredItems.length / uniqueDays.length.clamp(1, 100000))
                  .toStringAsFixed(1);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Highlights', style: textTheme.titleLarge),
              const SizedBox(height: 10),
              _WindowSelector(
                selected: _window,
                onSelected: (window) {
                  setState(() {
                    _window = window;
                  });
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overview', style: textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Text(
                        windowRange,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _KpiTile(
                            icon: Icons.menu_book_outlined,
                            label: 'Entries',
                            value: '${filteredItems.length}',
                          ),
                          _KpiTile(
                            icon: Icons.calendar_month_outlined,
                            label: 'Active days',
                            value: '${uniqueDays.length}',
                          ),
                          _KpiTile(
                            icon: Icons.local_fire_department_outlined,
                            label: 'Streak',
                            value: '$streak d',
                          ),
                          _KpiTile(
                            icon: Icons.stacked_line_chart_outlined,
                            label: 'Avg/day',
                            value: avgEntries,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Smart insights', style: textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _InsightLine(
                        icon: Icons.psychology_alt_outlined,
                        text: topMoodEntry == null
                            ? 'No dominant mood yet.'
                            : 'Dominant mood is $topMoodLabel at $topMoodShare% of all mood signals.',
                      ),
                      const SizedBox(height: 10),
                      _InsightLine(
                        icon: Icons.fact_check_outlined,
                        text:
                            'Check-in consistency is $consistency% (${percentString(metrics.preCount, filteredItems.length)} pre, ${percentString(metrics.postCount, filteredItems.length)} post).',
                      ),
                      const SizedBox(height: 10),
                      _InsightLine(
                        icon: Icons.today_outlined,
                        text: busiestWeekday == null
                            ? 'Not enough data for weekday patterns yet.'
                            : 'Most active day is $busiestWeekday.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Mood rhythm', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RhythmChart(series: metrics.dailySeries),
                      const SizedBox(height: 8),
                      Text(
                        '${DateFormat.MMMd().format(metrics.dailySeries.first.day)} - ${DateFormat.MMMd().format(metrics.dailySeries.last.day)}',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Mood balance', style: textTheme.titleLarge),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _MoodPie(
                    slices: metrics.moodSorted
                        .map(
                          (entry) => _PieSlice(
                            label:
                                EmotionCatalog.byId(entry.key)?.label ??
                                entry.key,
                            value: entry.value,
                            color: emotionColor(context, entry.key),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...metrics.moodSorted.take(6).map((entry) {
                final label =
                    EmotionCatalog.byId(entry.key)?.label ?? entry.key;
                final ratio =
                    entry.value / metrics.totalMoodSamples.clamp(1, 1000000);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MoodRow(
                    label: label,
                    count: entry.value,
                    ratio: ratio,
                    color: emotionColor(context, entry.key),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  List<JournalEntry> _applyWindow(
    List<JournalEntry> items,
    _InsightsWindow window,
  ) {
    if (window.days == null) {
      return items;
    }

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: window.days! - 1));
    return items.where((entry) => entry.createdAt.isAfter(cutoff)).toList();
  }

  int _currentEntryStreak(List<JournalEntry> items) {
    if (items.isEmpty) {
      return 0;
    }

    final days = items
        .map(
          (entry) => DateTime(
            entry.createdAt.year,
            entry.createdAt.month,
            entry.createdAt.day,
          ),
        )
        .toSet();

    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    var streak = 0;

    while (days.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  String? _busiestWeekday(List<JournalEntry> items) {
    if (items.isEmpty) {
      return null;
    }

    final counts = <int, int>{};
    for (final entry in items) {
      counts.update(
        entry.createdAt.weekday,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) {
      return null;
    }

    return DateFormat.EEEE().format(DateTime(2024, 1, sorted.first.key));
  }
}

class _WindowSelector extends StatelessWidget {
  const _WindowSelector({required this.selected, required this.onSelected});

  final _InsightsWindow selected;
  final ValueChanged<_InsightsWindow> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_InsightsWindow>(
      showSelectedIcon: false,
      segments: _InsightsWindow.values
          .map(
            (window) => ButtonSegment<_InsightsWindow>(
              value: window,
              label: Text(window.label),
            ),
          )
          .toList(),
      selected: <_InsightsWindow>{selected},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onSelected(selection.first);
        }
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _PieSlice {
  const _PieSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _MoodPie extends StatelessWidget {
  const _MoodPie({required this.slices});

  final List<_PieSlice> slices;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(painter: _PiePainter(slices: slices)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices.take(6).map((slice) {
              final ratio = total == 0
                  ? 0
                  : (slice.value / total * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: slice.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(slice.label, overflow: TextOverflow.ellipsis),
                    ),
                    Text('$ratio%'),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.slices});

  final List<_PieSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    if (total == 0) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = (slice.value / total) * (2 * math.pi);
      final paint = Paint()..color = slice.color;
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }

    final holePaint = Paint()
      ..color = Colors.black.withValues(
        alpha:
            ThemeData.estimateBrightnessForColor(slices.first.color) ==
                Brightness.dark
            ? 0.28
            : 0.08,
      );
    canvas.drawCircle(center, radius * 0.42, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({
    required this.label,
    required this.count,
    required this.ratio,
    required this.color,
  });

  final String label;
  final int count;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text('$count', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _RhythmChart extends StatelessWidget {
  const _RhythmChart({required this.series});

  final List<RhythmPoint> series;

  @override
  Widget build(BuildContext context) {
    final maxCount = series
        .map((point) => point.count)
        .fold<int>(1, (value, element) => element > value ? element : value);

    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: series.map((point) {
          final height = 12 + (point.count / maxCount) * 72;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: point.count == 0 || point.primaryId == null
                      ? Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.15)
                      : emotionColor(
                          context,
                          point.primaryId!,
                        ).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
