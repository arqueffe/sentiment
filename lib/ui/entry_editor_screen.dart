import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import 'package:sentiment/models/emotion.dart';
import 'package:sentiment/models/entry.dart';
import 'package:sentiment/state/providers.dart';
import 'package:sentiment/ui/widgets/annotated_text_controller.dart';
import 'package:sentiment/ui/widgets/emotion_picker.dart';
import 'package:sentiment/ui/widgets/mood_chip.dart';
import 'package:sentiment/ui/widgets/sentence_emotion_overlay.dart';
import 'package:sentiment/ui/widgets/settings_button.dart';

class EntryEditorScreen extends ConsumerStatefulWidget {
  const EntryEditorScreen({super.key});

  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends ConsumerState<EntryEditorScreen> {
  final _bodyController = AnnotatedTextController();
  final _bodyScrollController = ScrollController();
  final _pageController = PageController();

  static const _writeLineSpacing = 2.0;
  static const _writeFieldContentPadding = EdgeInsets.fromLTRB(12, 12, 12, 12);
  static const _mobileEditorBadgeVerticalOffset = 6.0;

  EmotionSelection? _preMood;
  EmotionSelection? _postMood;
  int _stepIndex = 0;
  bool _isAdvancing = false;

  static const _titles = [
    'Feel before',
    'Write entry',
    'Detected emotions',
    'Feel after',
  ];

  @override
  void initState() {
    super.initState();
  }

  void _onBodyChanged(String value) {
    ref.read(sentenceEmotionControllerProvider.notifier).setBody(value);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _bodyScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickMood({required bool isPre}) async {
    final selection = await showEmotionPicker(context);
    if (selection == null) {
      return;
    }
    setState(() {
      if (isPre) {
        _preMood = selection;
      } else {
        _postMood = selection;
      }
    });
  }

  Future<void> _save() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      await _goToStep(1);
      return;
    }
    final entry = JournalEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      body: body,
      createdAt: DateTime.now(),
      preMood: _preMood == null
          ? null
          : EmotionSelectionHive.fromDomain(_preMood!),
      postMood: _postMood == null
          ? null
          : EmotionSelectionHive.fromDomain(_postMood!),
      sentenceAnnotations: ref
          .read(sentenceEmotionControllerProvider)
          .annotations
          .map(SentenceEmotionAnnotationHive.fromDomain)
          .toList(),
    );
    await ref.read(entryControllerProvider).addEntry(entry);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _goToStep(int step) async {
    if (step != 1) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _stepIndex = step;
    });
  }

  Future<void> _next() async {
    if (_isAdvancing) {
      return;
    }
    if (_stepIndex >= 3) {
      await _save();
      return;
    }

    if (_stepIndex == 1) {
      setState(() {
        _isAdvancing = true;
      });
      try {
        await ref
            .read(sentenceEmotionControllerProvider.notifier)
            .prepareForNext(_bodyController.text);
      } finally {
        if (mounted) {
          setState(() {
            _isAdvancing = false;
          });
        }
      }
    }

    await _goToStep(_stepIndex + 1);
  }

  Future<void> _previous() async {
    if (_stepIndex == 0) {
      Navigator.of(context).pop();
      return;
    }
    await _goToStep(_stepIndex - 1);
  }

  @override
  Widget build(BuildContext context) {
    final now = intl.DateFormat.yMMMMd().add_Hm().format(DateTime.now());
    final hasText = _bodyController.text.trim().isNotEmpty;
    final sentenceEmotionState = ref.watch(sentenceEmotionControllerProvider);
    final annotations = sentenceEmotionState.annotations;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _bodyController.setAnnotations(annotations);
    });
    final canContinue = (_stepIndex == 1 ? hasText : true) && !_isAdvancing;
    final editorBadgeVerticalOffset = switch (Theme.of(context).platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS => _mobileEditorBadgeVerticalOffset,
      _ => 0.0,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_stepIndex]),
        actions: const [SettingsButton()],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: LinearProgressIndicator(
                  value: (_stepIndex + 1) / 4,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MoodStep(
                      prompt: 'How do you feel before writing?',
                      value: _preMood,
                      role: 'Before',
                      onPick: () => _pickMood(isPre: true),
                      onClear: _preMood == null
                          ? null
                          : () {
                              setState(() {
                                _preMood = null;
                              });
                            },
                    ),
                    _WriteStep(
                      bodyController: _bodyController,
                      scrollController: _bodyScrollController,
                      annotations: annotations,
                      now: now,
                      isClassifying: sentenceEmotionState.isClassifying,
                      lineSpacing: _writeLineSpacing,
                      contentPadding: _writeFieldContentPadding,
                      badgeVerticalOffset: editorBadgeVerticalOffset,
                      onChanged: _onBodyChanged,
                    ),
                    _DetectedStatsStep(
                      counts: sentenceEmotionState.counts,
                      totalClassified: sentenceEmotionState.annotations.length,
                      overallModelLabel: sentenceEmotionState.overallModelLabel,
                      overallEmotionConfidence:
                          sentenceEmotionState.overallEmotionConfidence,
                      overallEmotionChunkCount:
                          sentenceEmotionState.overallEmotionChunkCount,
                      overallDistribution:
                          sentenceEmotionState.overallDistribution,
                    ),
                    _MoodStep(
                      prompt: 'How do you feel after writing?',
                      value: _postMood,
                      role: 'After',
                      onPick: () => _pickMood(isPre: false),
                      onClear: _postMood == null
                          ? null
                          : () {
                              setState(() {
                                _postMood = null;
                              });
                            },
                      secondaryActionLabel: _preMood == null
                          ? null
                          : 'Use same as before',
                      onSecondaryAction: _preMood == null
                          ? null
                          : () {
                              setState(() {
                                _postMood = _preMood;
                              });
                            },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _isAdvancing ? null : _previous,
                      child: Text(_stepIndex == 0 ? 'Cancel' : 'Back'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: canContinue ? _next : null,
                      child: Text(_stepIndex == 3 ? 'Save' : 'Next'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isAdvancing)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.scrim.withAlpha(115),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Analyzing entry...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodStep extends StatelessWidget {
  const _MoodStep({
    required this.prompt,
    required this.value,
    required this.role,
    required this.onPick,
    this.onClear,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String prompt;
  final EmotionSelection? value;
  final String role;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(
          'Pick a broad feeling, then go deeper if you want.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        MoodChip(
          label: value?.label ?? 'Pick mood',
          selection: value,
          role: role,
          onTap: onPick,
        ),
        if (onClear != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Remove feeling'),
          ),
        ],
        if (secondaryActionLabel != null && onSecondaryAction != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onSecondaryAction,
            icon: const Icon(Icons.copy_outlined),
            label: Text(secondaryActionLabel!),
          ),
        ],
      ],
    );
  }
}

class _WriteStep extends StatelessWidget {
  const _WriteStep({
    required this.bodyController,
    required this.scrollController,
    required this.annotations,
    required this.now,
    required this.isClassifying,
    required this.lineSpacing,
    required this.contentPadding,
    required this.badgeVerticalOffset,
    required this.onChanged,
  });

  final AnnotatedTextController bodyController;
  final ScrollController scrollController;
  final List<SentenceEmotionAnnotation> annotations;
  final String now;
  final bool isClassifying;
  final double lineSpacing;
  final EdgeInsets contentPadding;
  final double badgeVerticalOffset;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorByEmotionId = emotionColorById(context, annotations);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(now, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final textStyle = Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: lineSpacing);
            return Stack(
              children: [
                TextField(
                  controller: bodyController,
                  scrollController: scrollController,
                  onChanged: onChanged,
                  maxLines: 14,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: textStyle,
                  strutStyle: StrutStyle(
                    height: lineSpacing,
                    forceStrutHeight: true,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write freely...\nNothing leaves your device.',
                    contentPadding: contentPadding,
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ListenableBuilder(
                      listenable: scrollController,
                      builder: (context, _) => CustomPaint(
                        painter: SentenceEmotionOverlayPainter(
                          text: bodyController.text,
                          annotations: annotations,
                          textStyle: textStyle ?? const TextStyle(),
                          textDirection: Directionality.of(context),
                          colorByEmotionId: colorByEmotionId,
                          fallbackColor: Theme.of(context).colorScheme.primary,
                          maxWidth: constraints.maxWidth,
                          contentPadding: contentPadding,
                          scrollOffset: scrollController.hasClients
                              ? scrollController.offset
                              : 0.0,
                          badgeVerticalOffset: badgeVerticalOffset,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.9,
                      child: _InferenceCornerLogo(isSpinning: isClassifying),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InferenceCornerLogo extends StatefulWidget {
  const _InferenceCornerLogo({required this.isSpinning});

  final bool isSpinning;

  @override
  State<_InferenceCornerLogo> createState() => _InferenceCornerLogoState();
}

class _InferenceCornerLogoState extends State<_InferenceCornerLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _InferenceCornerLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.isSpinning) {
      _rotationController.repeat();
      return;
    }
    _rotationController
      ..stop()
      ..value = 0;
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 16,
      child: RotationTransition(
        turns: _rotationController,
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
    );
  }
}

class _DetectedStatsStep extends StatelessWidget {
  const _DetectedStatsStep({
    required this.counts,
    required this.totalClassified,
    required this.overallModelLabel,
    required this.overallEmotionConfidence,
    required this.overallEmotionChunkCount,
    required this.overallDistribution,
  });

  final Map<String, int> counts;
  final int totalClassified;
  final String overallModelLabel;
  final double? overallEmotionConfidence;
  final int overallEmotionChunkCount;
  final Map<String, double> overallDistribution;

  String _formatLabel(String raw) {
    if (raw.trim().isEmpty) {
      return 'Unknown';
    }
    final normalized = raw.replaceAll('_', ' ').trim();
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final overallEntries = overallDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topOverall = overallEntries.take(5).toList();
    final hasOverall = overallModelLabel.trim().isNotEmpty;
    final confidenceText = overallEmotionConfidence == null
        ? null
        : '${(overallEmotionConfidence! * 100).toStringAsFixed(1)}%';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Detected emotions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          totalClassified == 0
              ? 'No completed sentences detected yet.'
              : '$totalClassified completed sentences were classified.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall entry estimate',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  hasOverall
                      ? _formatLabel(overallModelLabel)
                      : 'Write more text to estimate overall emotion.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (hasOverall && confidenceText != null)
                  Text(
                    'Confidence: $confidenceText',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (hasOverall)
                  Text(
                    overallEmotionChunkCount > 1
                        ? 'Based on $overallEmotionChunkCount averaged text chunks.'
                        : 'Based on a single text chunk.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (topOverall.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final item in topOverall)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(_formatLabel(item.key))),
                          Text('${(item.value * 100).toStringAsFixed(1)}%'),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Text(
            'Finish at least one sentence with punctuation to see emotion stats.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        for (final item in entries)
          Card(
            child: ListTile(
              title: Text(EmotionCatalog.byId(item.key)?.label ?? item.key),
              trailing: Text(item.value.toString()),
            ),
          ),
      ],
    );
  }
}
