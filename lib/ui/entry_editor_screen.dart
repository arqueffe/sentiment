import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sentiment/models/emotion.dart';
import 'package:sentiment/models/entry.dart';
import 'package:sentiment/state/providers.dart';
import 'package:sentiment/ui/widgets/annotated_text_controller.dart';
import 'package:sentiment/ui/widgets/emotion_picker.dart';
import 'package:sentiment/ui/widgets/mood_chip.dart';
import 'package:sentiment/ui/widgets/settings_button.dart';

class EntryEditorScreen extends ConsumerStatefulWidget {
  const EntryEditorScreen({super.key});

  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends ConsumerState<EntryEditorScreen> {
  final _bodyController = AnnotatedTextController();
  final _pageController = PageController();

  EmotionSelection? _preMood;
  EmotionSelection? _postMood;
  String? _hoveredEmotionLabel;
  int _stepIndex = 0;

  static const _titles = [
    'Feel before',
    'Write entry',
    'Detected emotions',
    'Feel after',
  ];

  @override
  void initState() {
    super.initState();
    _bodyController.onAnnotationHover = _onAnnotationHover;
  }

  void _onAnnotationHover(SentenceEmotionAnnotation? annotation) {
    final primaryEmotionId = annotation?.primaryEmotionId;
    final nextLabel = primaryEmotionId == null
        ? null
        : (EmotionCatalog.byId(primaryEmotionId)?.label ?? primaryEmotionId);
    if (_hoveredEmotionLabel == nextLabel || !mounted) {
      return;
    }
    setState(() {
      _hoveredEmotionLabel = nextLabel;
    });
  }

  void _onBodyChanged(String value) {
    ref.read(sentenceEmotionControllerProvider.notifier).setBody(value);
    if (_hoveredEmotionLabel != null) {
      _hoveredEmotionLabel = null;
    }
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _bodyController.dispose();
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
    if (_stepIndex >= 3) {
      await _save();
      return;
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
    final now = DateFormat.yMMMMd().add_Hm().format(DateTime.now());
    final hasText = _bodyController.text.trim().isNotEmpty;
    final sentenceEmotionState = ref.watch(sentenceEmotionControllerProvider);
    final annotations = sentenceEmotionState.annotations;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _bodyController.setAnnotations(annotations);
    });
    final canContinue = _stepIndex == 1 ? hasText : true;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_stepIndex]),
        actions: const [SettingsButton()],
      ),
      body: Column(
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
                ),
                _WriteStep(
                  bodyController: _bodyController,
                  now: now,
                  isClassifying: sentenceEmotionState.isClassifying,
                  hoveredEmotionLabel: _hoveredEmotionLabel,
                  onChanged: _onBodyChanged,
                ),
                _DetectedStatsStep(
                  counts: sentenceEmotionState.counts,
                  totalClassified: sentenceEmotionState.annotations.length,
                ),
                _MoodStep(
                  prompt: 'How do you feel after writing?',
                  value: _postMood,
                  role: 'After',
                  onPick: () => _pickMood(isPre: false),
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
                  onPressed: _previous,
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
    );
  }
}

class _MoodStep extends StatelessWidget {
  const _MoodStep({
    required this.prompt,
    required this.value,
    required this.role,
    required this.onPick,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String prompt;
  final EmotionSelection? value;
  final String role;
  final VoidCallback onPick;
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
    required this.now,
    required this.isClassifying,
    required this.hoveredEmotionLabel,
    required this.onChanged,
  });

  final AnnotatedTextController bodyController;
  final String now;
  final bool isClassifying;
  final String? hoveredEmotionLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(now, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 14),
        TextField(
          controller: bodyController,
          onChanged: onChanged,
          maxLines: 14,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Write freely...\nNothing leaves your device.',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isClassifying
              ? 'Detecting emotion for completed sentences...'
              : 'Completed sentences are underlined by detected emotion.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (hoveredEmotionLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            'Hovered sentence emotion: $hoveredEmotionLabel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _DetectedStatsStep extends StatelessWidget {
  const _DetectedStatsStep({
    required this.counts,
    required this.totalClassified,
  });

  final Map<String, int> counts;
  final int totalClassified;

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
