import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sentiment/models/emotion.dart';
import 'package:sentiment/models/entry.dart';
import 'package:sentiment/state/providers.dart';
import 'package:sentiment/ui/widgets/emotion_picker.dart';
import 'package:sentiment/ui/widgets/mood_chip.dart';
import 'package:sentiment/ui/widgets/settings_button.dart';

class EntryEditorScreen extends ConsumerStatefulWidget {
  const EntryEditorScreen({super.key});

  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends ConsumerState<EntryEditorScreen> {
  final _bodyController = TextEditingController();
  final _pageController = PageController();

  EmotionSelection? _preMood;
  EmotionSelection? _postMood;
  int _stepIndex = 0;

  static const _titles = ['Feel before', 'Write entry', 'Feel after'];

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(_onBodyChanged);
  }

  void _onBodyChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _bodyController.removeListener(_onBodyChanged);
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
      _goToStep(1);
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
    if (_stepIndex >= 2) {
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
              value: (_stepIndex + 1) / 3,
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
                _WriteStep(bodyController: _bodyController, now: now),
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
                  child: Text(_stepIndex == 2 ? 'Save' : 'Next'),
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
  const _WriteStep({required this.bodyController, required this.now});

  final TextEditingController bodyController;
  final String now;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(now, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 14),
        TextField(
          controller: bodyController,
          maxLines: 14,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Write freely...\nNothing leaves your device.',
          ),
        ),
      ],
    );
  }
}
