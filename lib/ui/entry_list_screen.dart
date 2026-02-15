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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? now,
      firstDate: DateTime(2018),
      lastDate: now,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
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
              child: Text(
                _selectedDay == null
                    ? 'No entries yet'
                    : 'No entries on this day',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
      bottomSheet: _selectedDay == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMMd().format(_selectedDay!),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton(onPressed: _clearDate, child: const Text('Clear')),
                ],
              ),
            ),
    );
  }
}
