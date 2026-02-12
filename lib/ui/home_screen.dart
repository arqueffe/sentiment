import 'package:flutter/material.dart';

import 'package:sentiment/router/app_router.dart';
import 'package:sentiment/ui/entry_list_screen.dart';
import 'package:sentiment/ui/insights_screen.dart';
import 'package:sentiment/ui/onboarding_prefs.dart';
import 'package:sentiment/ui/widgets/onboarding_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _maybeShowOnboarding();
  }

  Future<void> _maybeShowOnboarding() async {
    final seen = await OnboardingPrefs.hasSeen();
    if (seen || !mounted) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => const OnboardingDialog(),
    );
    await OnboardingPrefs.markSeen();
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [EntryListScreen(), InsightsScreen()];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.newEntry),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Entries',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
