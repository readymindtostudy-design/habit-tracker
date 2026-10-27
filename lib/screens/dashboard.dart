import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../sheets.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';
import 'wizard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  final void Function(int) onNavigate;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final DateTime now = DateTime.now();
    final String dateStr =
        '${weekdaysShort[now.weekday % 7]}, ${ord(now.day)} ${monthsShort[now.month - 1]}';

    final List<Habit> act = app.activeHabits;
    final List<Habit> daily = app.dailyHabits;
    final List<Habit> weekly = app.weeklyHabits;
    final int done = daily.where(app.doneToday).length;
    final List<Habit> ranked = List<Habit>.of(act)
      ..sort((Habit a, Habit b) => app.streak(b).compareTo(app.streak(a)));
    final List<Task> openTasks = app.openTasks;
    final double timedToday = app.pomoLog[todayKey()]?.minutes ?? 0.0;
    final List<MapEntry<String, Habit>> upcoming = app.upcomingReminders();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
      children: <Widget>[
        Text('${greeting()}. $dateStr',
            style: const TextStyle(color: AppColors.muted, fontSize: 14)),
        const SizedBox(height: 16),
        if (act.isEmpty && app.tasks.isEmpty) _welcome(context),
        AppCard(
          child: Row(
            children: <Widget>[
              BigRing(done: done, total: daily.length),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    StatTile(
                      value: '${ranked.isEmpty ? 0 : app.streak(ranked.first)}',
                      label: 'Best streak',
                    ),
                    const SizedBox(height: 14),
                    StatTile(
                        value: fmtMinutes(timedToday), label: 'Timed today'),
                    const SizedBox(height: 14),
                    StatTile(
                        value: '${openTasks.length}', label: 'Open tasks'),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (upcoming.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          _nextUp(context, upcoming.first),
        ],
        SectionHeader(
          title: 'Today\u2019s habits',
          action: 'See all',
          onAction: () => onNavigate(1),
        ),
        if (daily.isEmpty)
          _empty('No daily habits yet. Tap + to create one.')
        else
          ...daily.map((Habit h) => _DashRow(habit: h, app: app)),
        if (weekly.isNotEmpty) ...<Widget>[
          const SectionHeader(title: 'Weekly goals'),
          ...weekly.map((Habit h) => _DashRow(habit: h, app: app)),
        ],
        if (ranked.isNotEmpty && app.streak(ranked.first) > 0) ...<Widget>[
          const SectionHeader(title: 'Streaks'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ranked
                .where((Habit h) => app.streak(h) > 0)
                .take(6)
                .map((Habit h) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tint(h.color, 0.5)),
                      ),
                      child: Text(
                        '${h.icon} ${h.name}  ${app.streak(h)}${h.isWeekly ? ' wk' : ' d'}',
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ))
                .toList(),
          ),
        ],
        _consistency(context, app, daily),
        const SectionHeader(title: 'Where your time goes'),
        _timeCard(app, 7),
        if (openTasks.isNotEmpty) ...<Widget>[
          SectionHeader(
            title: 'Tasks',
            action: 'See all',
            onAction: () => onNavigate(3),
          ),
          ...openTasks.take(4).map((Task t) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.circle_outlined,
                        color: AppColors.muted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(t.text)),
                  ],
                ),
              )),
          if (openTasks.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+${openTasks.length - 4} more',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
            ),
        ],
      ],
    );
  }

  Widget _welcome(BuildContext context) {
    return AppCard(
      child: Column(
        children: <Widget>[
          const Text('🌱', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 8),
          const Text('Welcome',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
            'Create your first habit to start tracking. Everything you add is saved on this phone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => HabitWizard.open(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.greenInk,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Create a habit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextUp(BuildContext context, MapEntry<String, Habit> entry) {
    final Habit h = entry.value;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onNavigate(2),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tint(h.color, 0.5), width: 1.4),
          ),
          child: Row(
            children: <Widget>[
              IconBubble(icon: h.icon, color: h.color, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Next up: ${h.name}',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 3),
                    Text('Reminder at ${fmtTime(entry.key)}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _consistency(BuildContext context, AppState app, List<Habit> daily) {
    if (daily.isEmpty) return const SizedBox.shrink();
    final List<double> bars = <double>[];
    final List<int> days = <int>[];
    double sum = 0;
    int n = 0;
    for (int i = 13; i >= 0; i--) {
      final DateTime d = DateTime.now().subtract(Duration(days: i));
      final String k = dateKey(d);
      int tot = 0;
      int met = 0;
      for (final Habit h in daily) {
        if (k.compareTo(h.createdAt) < 0) continue;
        tot++;
        if (app.dayMet(h, k)) met++;
      }
      final double pct = tot == 0 ? 0.0 : met / tot;
      if (tot > 0) {
        sum += pct;
        n++;
      }
      bars.add(pct);
      days.add(d.day);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Consistency, last 14 days'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 84,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List<Widget>.generate(bars.length, (int i) {
                    final bool today = i == bars.length - 1;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              height: 4 + bars[i] * 60,
                              decoration: BoxDecoration(
                                color: today
                                    ? AppColors.green
                                    : AppColors.green
                                        .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('${days[i]}',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                n == 0
                    ? 'Nothing to measure yet.'
                    : 'You completed ${(sum / n * 100).round()}% of your daily habits on average.',
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeCard(AppState app, int days) {
    final List<DonutSlice> slices = timeSlices(app, days);
    final double total =
        slices.fold<double>(0, (double a, DonutSlice s) => a + s.minutes);
    if (total <= 0) {
      return _empty('No focus time logged in the last $days days.');
    }
    return AppCard(
      child: Row(
        children: <Widget>[
          DonutChart(
            slices: slices,
            size: 150,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(fmtMinutes(total),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const Text('total',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: slices
                  .map((DonutSlice s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: s.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(s.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14)),
                            ),
                            Text(fmtMinutes(s.minutes),
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.muted)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(message,
            style: const TextStyle(color: AppColors.muted, height: 1.4)),
      );
}

class _DashRow extends StatelessWidget {
  const _DashRow({required this.habit, required this.app});

  final Habit habit;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final bool done = app.doneToday(habit);
    final double progress = app.todayProgress(habit);
    final Color color = hexColor(habit.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showLogSheet(context, habit),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                IconBubble(icon: habit.icon, color: habit.color, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 6),
                      ProgressBar(value: progress, color: color, height: 5),
                      const SizedBox(height: 5),
                      Text(app.progressText(habit),
                          style: TextStyle(
                              fontSize: 12.5,
                              color:
                                  done ? AppColors.green : AppColors.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (habit.kind == HabitKind.tick)
                  Material(
                    color: done ? color : Colors.transparent,
                    shape: CircleBorder(
                        side: BorderSide(color: color, width: 2)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => app.toggleTick(habit, todayKey()),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.check_rounded,
                            size: 22,
                            color:
                                done ? AppColors.greenInk : Colors.transparent),
                      ),
                    ),
                  )
                else
                  Material(
                    color: color,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () => showLogSheet(context, habit),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.add_rounded,
                            color: AppColors.greenInk, size: 24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minutes per timer over the last [days] days, as donut slices.
List<DonutSlice> timeSlices(AppState app, int days) {
  final Map<String, double> by = <String, double>{};
  for (int i = 0; i < days; i++) {
    final PomoDay? day =
        app.pomoLog[dateKey(DateTime.now().subtract(Duration(days: i)))];
    if (day == null) continue;
    day.by.forEach((String k, double v) {
      by[k] = (by[k] ?? 0.0) + v;
    });
  }
  final List<DonutSlice> slices = <DonutSlice>[];
  for (final FocusTimer t in app.timers) {
    final double m = by[t.id] ?? 0.0;
    if (m > 0) slices.add(DonutSlice(t.name, m, hexColor(t.color)));
  }
  return slices;
}
