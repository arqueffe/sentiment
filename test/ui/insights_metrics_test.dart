import 'package:flutter_test/flutter_test.dart';

import 'package:sentiment/models/entry.dart';
import 'package:sentiment/ui/insights/insights_metrics.dart';

void main() {
  group('percentString', () {
    test('returns zero when total is zero', () {
      expect(percentString(3, 0), '0%');
    });

    test('returns rounded percentage', () {
      expect(percentString(1, 3), '33%');
    });
  });

  group('buildInsightsMetrics', () {
    test('aggregates pre/post and sentence mood counts', () {
      final now = DateTime.now();
      final entries = <JournalEntry>[
        JournalEntry(
          id: 'e1',
          body: 'One',
          createdAt: now,
          preMood: EmotionSelectionHive(primaryId: 'joy'),
          postMood: EmotionSelectionHive(primaryId: 'trust'),
          sentenceAnnotations: [
            SentenceEmotionAnnotationHive(
              start: 0,
              end: 3,
              sentence: 'One',
              modelLabel: 'happiness',
              primaryEmotionId: 'joy',
              confidence: 0.9,
            ),
            SentenceEmotionAnnotationHive(
              start: 0,
              end: 3,
              sentence: 'One',
              modelLabel: 'happiness',
              primaryEmotionId: 'joy',
              confidence: 0.8,
            ),
          ],
        ),
      ];

      final metrics = buildInsightsMetrics(entries);

      expect(metrics.preCount, 1);
      expect(metrics.postCount, 1);
      expect(metrics.totalMoodSamples, 4);
      expect(metrics.moodSorted.first.key, 'joy');
      expect(metrics.moodSorted.first.value, 3);
    });

    test('creates fixed-size daily rhythm series', () {
      final metrics = buildInsightsMetrics(const [], rhythmDays: 10);
      expect(metrics.dailySeries.length, 10);
      expect(metrics.dailySeries.every((point) => point.count == 0), isTrue);
    });
  });
}
