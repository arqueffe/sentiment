import 'package:flutter/material.dart';

import 'package:sentiment/models/emotion.dart';
import 'package:sentiment/models/entry.dart';
import 'package:sentiment/ui/widgets/mood_chip.dart';

class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    required this.dateLabel,
    this.onTap,
  });

  final JournalEntry entry;
  final String dateLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mainSentenceEmotion = _mainSentenceEmotionSelection(
      entry.sentenceEmotionAnnotations,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final hasTags =
        entry.preMoodSelection != null ||
        entry.postMoodSelection != null ||
        mainSentenceEmotion != null;
    final analyzedCount = entry.sentenceEmotionAnnotations.length;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                entry.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (analyzedCount > 0) ...[
                const SizedBox(height: 10),
                Text(
                  '$analyzedCount ${analyzedCount == 1 ? 'sentence' : 'sentences'} analyzed',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (hasTags)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (entry.preMoodSelection != null)
                        MoodChip(
                          label: entry.preMoodSelection!.label,
                          selection: entry.preMoodSelection,
                          role: 'Before',
                        ),
                      if (entry.postMoodSelection != null)
                        MoodChip(
                          label: entry.postMoodSelection!.label,
                          selection: entry.postMoodSelection,
                          role: 'After',
                        ),
                      if (mainSentenceEmotion != null)
                        MoodChip(
                          label: mainSentenceEmotion.label,
                          selection: mainSentenceEmotion,
                          role: 'Detected',
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  EmotionSelection? _mainSentenceEmotionSelection(
    List<SentenceEmotionAnnotation> annotations,
  ) {
    final counts = <String, int>{};
    for (final annotation in annotations) {
      final emotionId =
          annotation.detectedEmotionId ?? annotation.primaryEmotionId;
      if (emotionId == null) {
        continue;
      }
      counts.update(emotionId, (value) => value + 1, ifAbsent: () => 1);
    }

    if (counts.isEmpty) {
      return null;
    }

    String? dominantId;
    var dominantCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > dominantCount) {
        dominantId = entry.key;
        dominantCount = entry.value;
      }
    }

    if (dominantId == null) {
      return null;
    }

    final primaryId = EmotionCatalog.primaryIdFor(dominantId) ?? dominantId;
    final secondaryId = dominantId == primaryId ? null : dominantId;
    return EmotionSelection(primaryId: primaryId, secondaryId: secondaryId);
  }
}
