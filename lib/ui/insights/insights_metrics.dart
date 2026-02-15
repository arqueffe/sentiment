import 'package:sentiment/models/entry.dart';

class RhythmPoint {
  const RhythmPoint({required this.day, required this.count, this.primaryId});

  final DateTime day;
  final int count;
  final String? primaryId;
}

class InsightsMetrics {
  const InsightsMetrics({
    required this.preCount,
    required this.postCount,
    required this.totalMoodSamples,
    required this.moodSorted,
    required this.dailySeries,
  });

  final int preCount;
  final int postCount;
  final int totalMoodSamples;
  final List<MapEntry<String, int>> moodSorted;
  final List<RhythmPoint> dailySeries;
}

InsightsMetrics buildInsightsMetrics(
  List<JournalEntry> filteredItems, {
  int rhythmDays = 14,
}) {
  final moodCounts = <String, int>{};
  final dayCounts = <DateTime, int>{};
  final dayDominantMood = <DateTime, String>{};
  var preCount = 0;
  var postCount = 0;
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
    final detectedCounts = <String, int>{};
    for (final annotation in entry.sentenceEmotionAnnotations) {
      final detected = annotation.primaryEmotionId;
      if (detected == null) {
        continue;
      }
      detectedCounts.update(detected, (value) => value + 1, ifAbsent: () => 1);
      moodCounts[detected] = (moodCounts[detected] ?? 0) + 1;
      totalMoodSamples += 1;
    }

    String? dominantDetected;
    var dominantDetectedCount = 0;
    for (final detectedEntry in detectedCounts.entries) {
      if (detectedEntry.value > dominantDetectedCount) {
        dominantDetected = detectedEntry.key;
        dominantDetectedCount = detectedEntry.value;
      }
    }

    if (post != null) {
      dayDominantMood[day] = post;
    } else if (pre != null) {
      dayDominantMood.putIfAbsent(day, () => pre);
    } else if (dominantDetected != null) {
      dayDominantMood.putIfAbsent(day, () => dominantDetected!);
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

  return InsightsMetrics(
    preCount: preCount,
    postCount: postCount,
    totalMoodSamples: totalMoodSamples,
    moodSorted: moodSorted,
    dailySeries: _lastNDays(dayCounts, dayDominantMood, rhythmDays),
  );
}

String percentString(int part, int total) {
  if (total == 0) {
    return '0%';
  }
  final value = (part / total * 100).round();
  return '$value%';
}

List<RhythmPoint> _lastNDays(
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
    return RhythmPoint(
      day: day,
      count: dayCounts[day] ?? 0,
      primaryId: dayDominantMood[day],
    );
  });
}
