import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';
import 'wizard.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final DateTime now = DateTime.now();
    final String dateStr =
        '${weekdaysShort[now.weekday % 7]}, ${ord(now.day)} ${monthsShort[now.month - 1]}';

    final List<Habit> withRem = app.activeHabits
        .where((Habit h) => h.reminders.isNotEmpty)
        .toList()
      ..sort((Habit a, Habit b) =>
          (a.reminders.isEmpty ? '99' : a.reminders.first)
              .compareTo(b.reminders.isEmpty ? '99' : b.reminders.first));
    final List<Habit> without = app.activeHabits
        .where((Habit h) => h.reminders.isEmpty)
        .toList();

    final List<MapEntry<String, Habit>> upcoming = app.upcomingReminders();
    final String? nextTime =
        upcoming.isEmpty ? null : upcoming.first.key;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
      children: <Widget>[
        Text(dateStr,
            style: const TextStyle(color: AppColors.muted, fontSize: 14)),
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            children: <Widget>[
              const Icon(Icons.notifications_active_outlined,
                  color: AppColors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  app.notificationsEnabled
                      ? 'Reminders fire as notifications, even when the app is closed.'
                      : 'Reminders are set. Enable notifications in Settings so they can reach you.',
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Today\u2019s reminders'),
        if (withRem.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No reminders yet. Edit a habit and add a time to be nudged.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
          )
        else
          ...withRem.map((Habit h) {
            final bool isNext = h.reminders.contains(nextTime);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isNext
                        ? AppColors.green
                        : tint(h.color, 0.45),
                    width: isNext ? 1.8 : 1.4,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconBubble(
                            icon: h.icon, color: h.color, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(h.name,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(
                                h.reminders.map(fmtTime).join('  •  '),
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                        if (isNext)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Next',
                                style: TextStyle(
                                    color: AppColors.green, fontSize: 12.5)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        if (without.isNotEmpty) ...<Widget>[
          const SectionHeader(title: 'No reminder set'),
          ...without.map((Habit h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => HabitWizard.open(context, existing: h),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: <Widget>[
                        IconBubble(
                            icon: h.icon, color: h.color, size: 40),
                        const SizedBox(width: 12),
                        Expanded(child: Text(h.name)),
                        const Icon(Icons.add_alarm,
                            color: AppColors.muted, size: 20),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ],
    );
  }
}
