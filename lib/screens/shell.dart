import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sheets.dart';
import '../store.dart';
import '../theme.dart';
import 'dashboard.dart';
import 'focus.dart';
import 'habits.dart';
import 'plan.dart';
import 'tasks.dart';
import 'wizard.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Dashboard',
    'Habits',
    'Plan',
    'Tasks',
    'Focus',
  ];

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    final List<Widget> pages = <Widget>[
      DashboardScreen(onNavigate: _go),
      const HabitsScreen(),
      const PlanScreen(),
      const TasksScreen(),
      const FocusScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => showInsightsSheet(context),
            icon: const Icon(Icons.insights),
            tooltip: 'Insights',
          ),
          IconButton(
            onPressed: () => showSettingsSheet(context),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: !app.loaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.green))
          : IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => HabitWizard.open(context),
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.greenInk,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New habit'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.green.withValues(alpha: 0.18),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.green),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: AppColors.green),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule, color: AppColors.green),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt),
            selectedIcon: Icon(Icons.task_alt, color: AppColors.green),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer, color: AppColors.green),
            label: 'Focus',
          ),
        ],
      ),
    );
  }
}
