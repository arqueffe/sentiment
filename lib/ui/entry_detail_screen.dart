import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sentiment/models/entry.dart';
import 'package:sentiment/models/emotion.dart';
import 'package:sentiment/state/providers.dart';
import 'package:sentiment/ui/widgets/mood_chip.dart';
import 'package:sentiment/ui/widgets/sentence_emotion_overlay.dart';
import 'package:sentiment/ui/widgets/settings_button.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entry});

  static const _bodyLineSpacing = 2.5;
  static const _detailBadgeVerticalOffset = 6.0;

  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annotationCount = entry.sentenceEmotionAnnotations.length;
    final detectedCounts = _detectedEmotionCounts(entry);
    final uniqueDetectedCount = detectedCounts.length;
    final dominantDetectedEmotionId = _dominantDetectedEmotionId(entry);
    final dominantDetectedCount = dominantDetectedEmotionId == null
        ? 0
        : (detectedCounts[dominantDetectedEmotionId] ?? 0);
    final dominantDetectedShare = annotationCount == 0
        ? 0
        : ((dominantDetectedCount / annotationCount) * 100).round();
    final topDetectedSummary = _topDetectedSummary(
      detectedCounts,
      totalAnnotations: annotationCount,
    );
    final dominantDetectedEmotionLabel = dominantDetectedEmotionId == null
        ? null
        : (EmotionCatalog.byId(dominantDetectedEmotionId)?.label ??
              dominantDetectedEmotionId);
    final averageConfidence = _averageConfidence(entry);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry'),
        actions: [
          IconButton(
            tooltip: 'Delete entry',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmAndDelete(context, ref),
          ),
          const SettingsButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMMd().add_Hm().format(entry.createdAt),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            SentenceEmotionOverlayText(
              text: entry.body,
              annotations: entry.sentenceEmotionAnnotations,
              textStyle: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: _bodyLineSpacing),
              strutStyle: const StrutStyle(
                height: _bodyLineSpacing,
                forceStrutHeight: true,
              ),
              badgeVerticalOffset: _detailBadgeVerticalOffset,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entry insights',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      annotationCount == 0
                          ? '• No sentence-level emotion tags were detected yet.'
                          : '• $annotationCount sentence-level emotion tags detected.',
                    ),
                    if (dominantDetectedEmotionLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '• Dominant detected emotion: $dominantDetectedEmotionLabel ($dominantDetectedShare%).',
                      ),
                    ],
                    if (uniqueDetectedCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '• Emotional variety: $uniqueDetectedCount distinct detected emotions.',
                      ),
                    ],
                    if (topDetectedSummary != null) ...[
                      const SizedBox(height: 8),
                      Text('• Top detected emotions: $topDetectedSummary.'),
                    ],
                    if (averageConfidence != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '• Average detection confidence: ${(averageConfidence * 100).round()}%.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (entry.preMoodSelection != null) ...[
              Text('Before', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              MoodChip(
                label: entry.preMoodSelection!.label,
                selection: entry.preMoodSelection,
                role: 'Before',
              ),
              const SizedBox(height: 16),
            ],
            if (entry.postMoodSelection != null) ...[
              Text('After', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              MoodChip(
                label: entry.postMoodSelection!.label,
                selection: entry.postMoodSelection,
                role: 'After',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            return AlertDialog(
              title: const Text('Delete entry?'),
              content: const Text(
                'This is a permanent deletion. This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await ref.read(entryControllerProvider).deleteEntry(entry.id);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  String? _dominantDetectedEmotionId(JournalEntry entry) {
    final counts = _detectedEmotionCounts(entry);

    String? dominantId;
    var dominantCount = 0;
    for (final item in counts.entries) {
      if (item.value > dominantCount) {
        dominantId = item.key;
        dominantCount = item.value;
      }
    }
    return dominantId;
  }

  double? _averageConfidence(JournalEntry entry) {
    final annotations = entry.sentenceEmotionAnnotations;
    if (annotations.isEmpty) {
      return null;
    }
    final total = annotations.fold<double>(
      0,
      (sum, annotation) => sum + annotation.confidence,
    );
    return total / annotations.length;
  }

  Map<String, int> _detectedEmotionCounts(JournalEntry entry) {
    final counts = <String, int>{};
    for (final annotation in entry.sentenceEmotionAnnotations) {
      final id = annotation.primaryEmotionId;
      if (id == null) {
        continue;
      }
      counts.update(id, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  String? _topDetectedSummary(
    Map<String, int> counts, {
    required int totalAnnotations,
  }) {
    if (counts.isEmpty || totalAnnotations == 0) {
      return null;
    }

    final top = counts.entries.toList()..sort((a, b) => b.value - a.value);
    return top
        .take(3)
        .map((entry) {
          final label = EmotionCatalog.byId(entry.key)?.label ?? entry.key;
          final share = ((entry.value / totalAnnotations) * 100).round();
          return '$label $share%';
        })
        .join(' · ');
  }
}
