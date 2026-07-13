import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/route_paths.dart';
import '../../features/dashboard/presentation/today_page.dart';
import '../../features/meal_capture/presentation/capture_preview_page.dart';
import '../../features/meal_history/presentation/history_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/weight_tracking/presentation/progress_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _pages = const [
    TodayPage(),
    CapturePreviewPage(),
    HistoryPage(),
    ProgressPage(),
    ProfilePage(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('NutriLens'), actions: [
        IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.settings))
      ]),
      body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index])),
      bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.today_outlined), label: 'Today'),
            NavigationDestination(
                icon: Icon(Icons.add_a_photo_outlined), label: 'Capture'),
            NavigationDestination(
                icon: Icon(Icons.history_outlined), label: 'History'),
            NavigationDestination(
                icon: Icon(Icons.show_chart_outlined), label: 'Progress'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Profile')
          ]));
}
