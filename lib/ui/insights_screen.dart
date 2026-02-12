import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'package:sentiment/models/emotion.dart';
import 'package:sentiment/models/entry.dart';
import 'package:sentiment/state/providers.dart';
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
        title: const Text('Insights'),
        actions: const [SettingsButton()],
      ),
      body: entries.when(
        data: (items) {
          final filteredItems = _applyWindow(items, _window);

          if (filteredItems.isEmpty) {
            return Center(
              child: Text(
                'No data in this time window',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          final moodCounts = <String, int>{};
          final dayCounts = <DateTime, int>{};
          final dayDominantMood = <DateTime, String>{};
          int preCount = 0;
          int postCount = 0;
          var totalMoodSamples = 0;

          for (final entry in filteredItems) {
            final day = DateTime(
              entry.createdAt.year,
              entry.createdAt.month,
              entry.createdAt.day,
            );
            dayCounts[day] = (dayCounts[day] ?? 0) + 1;

            final pre = entry.preMoodSelection?.primaryId;
            final post = entry.postMoodSelection?.primaryId;

            if (post != null) {
              dayDominantMood[day] = post;
            } else if (pre != null) {
              dayDominantMood.putIfAbsent(day, () => pre);
            }

            if (pre != null) {
              moodCounts[pre] = (moodCounts[pre] ?? 0) + 1;
              preCount += 1;
              totalMoodSamples += 1;
            }
            if (post != null) {
              moodCounts[post] = (moodCounts[post] ?? 0) + 1;
              postCount += 1;
              totalMoodSamples += 1;
            }
          }

          final moodSorted = moodCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final dailySeries = _lastNDays(dayCounts, dayDominantMood, 14);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Highlights', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _WindowSelector(
                selected: _window,
                onSelected: (window) {
                  setState(() {
                    _window = window;
                  });
                },
              ),
              const SizedBox(height: 12),
              _StatRow(
                label: 'Pre check-ins',
                value: _percent(preCount, filteredItems.length),
              ),
              _StatRow(
                label: 'Post check-ins',
                value: _percent(postCount, filteredItems.length),
              ),
              const SizedBox(height: 24),
              Text(
                'Mood rhythm',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _RhythmChart(series: dailySeries),
              const SizedBox(height: 8),
              Text(
                '${DateFormat.MMMd().format(dailySeries.first.day)} - ${DateFormat.MMMd().format(dailySeries.last.day)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'Mood balance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _MoodPie(
                slices: moodSorted
                    .map(
                      (entry) => _PieSlice(
                        label:
                            EmotionCatalog.byId(entry.key)?.label ?? entry.key,
                        value: entry.value,
                        color: emotionColor(context, entry.key),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              ...moodSorted.take(6).map((entry) {
                final label =
                    EmotionCatalog.byId(entry.key)?.label ?? entry.key;
                final ratio = entry.value / totalMoodSamples.clamp(1, 1000000);
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
}

class _WindowSelector extends StatelessWidget {
  const _WindowSelector({required this.selected, required this.onSelected});

  final _InsightsWindow selected;
  final ValueChanged<_InsightsWindow> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _InsightsWindow.values
          .map(
            (window) => ChoiceChip(
              label: Text(window.label),
              selected: selected == window,
              onSelected: (_) => onSelected(window),
            ),
          )
          .toList(),
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
          child: CustomPaint(
            painter: _PiePainter(slices: slices),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text('moods', style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
            ),
          ),
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
      ..color = Colors.black.withOpacity(
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

class _RhythmPoint {
  const _RhythmPoint({required this.day, required this.count, this.primaryId});

  final DateTime day;
  final int count;
  final String? primaryId;
}

List<_RhythmPoint> _lastNDays(
  Map<DateTime, int> dayCounts,
  Map<DateTime, String> dayDominantMood,
  int days,
) {
  final today = DateTime.now();
  final start = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: days - 1));
  return List.generate(days, (index) {
    final day = start.add(Duration(days: index));
    return _RhythmPoint(
      day: day,
      count: dayCounts[day] ?? 0,
      primaryId: dayDominantMood[day],
    );
  });
}

String _percent(int part, int total) {
  if (total == 0) {
    return '0%';
  }
  final value = (part / total * 100).round();
  return '$value%';
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
            backgroundColor: color.withOpacity(0.15),
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

  final List<_RhythmPoint> series;

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
                  color: point.count == 0
                      ? Theme.of(context).colorScheme.outline.withOpacity(0.15)
                      : emotionColor(
                          context,
                          point.primaryId ?? EmotionCatalog.wheel.first.id,
                        ).withOpacity(0.75),
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
