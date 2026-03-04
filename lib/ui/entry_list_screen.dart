import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sentiment/router/app_router.dart';
import 'package:sentiment/state/providers.dart';
import 'package:sentiment/ui/widgets/entry_card.dart';
import 'package:sentiment/ui/widgets/settings_button.dart';

class EntryListScreen extends ConsumerStatefulWidget {
  const EntryListScreen({super.key});

  @override
  ConsumerState<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends ConsumerState<EntryListScreen> {
  DateTime? _selectedDay;

  int _dateKey(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  Future<void> _pickDate() async {
    final items = await ref.read(entriesProvider.future);
    if (!mounted || items.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final selectableDateKeys = items
        .map((entry) => _dateKey(entry.createdAt))
        .toSet();
    final sortedEntryDates =
        items
            .map(
              (entry) => DateTime(
                entry.createdAt.year,
                entry.createdAt.month,
                entry.createdAt.day,
              ),
            )
            .toList()
          ..sort();

    final initialCandidate = _selectedDay ?? now;
    final initialDate = selectableDateKeys.contains(_dateKey(initialCandidate))
        ? initialCandidate
        : sortedEntryDates.last;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: sortedEntryDates.first,
      lastDate: now,
      selectableDayPredicate: (date) {
        return selectableDateKeys.contains(_dateKey(date));
      },
    );
    if (date == null) {
      return;
    }
    setState(() {
      _selectedDay = date;
    });
  }

  void _clearDate() {
    setState(() {
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 24, width: 24),
            const SizedBox(width: 8),
            const Text('Journal'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pick date',
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: _pickDate,
          ),
          const SettingsButton(),
        ],
      ),
      body: entries.when(
        data: (items) {
          final filtered = _selectedDay == null
              ? items
              : items
                    .where(
                      (entry) =>
                          entry.createdAt.year == _selectedDay!.year &&
                          entry.createdAt.month == _selectedDay!.month &&
                          entry.createdAt.day == _selectedDay!.day,
                    )
                    .toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 44,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedDay == null
                          ? 'No entries yet'
                          : 'No entries on this day',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }
          final title = _selectedDay == null
              ? 'All entries'
              : DateFormat.yMMMMd().format(_selectedDay!);
          final countLabel =
              '${filtered.length} ${filtered.length == 1 ? 'entry' : 'entries'}';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              countLabel,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedDay != null)
                        TextButton.icon(
                          onPressed: _clearDate,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return EntryCard(
                      entry: entry,
                      dateLabel: DateFormat.yMMMd().format(entry.createdAt),
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRouter.entryDetail, arguments: entry),
                    );
                  },
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemCount: filtered.length,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
