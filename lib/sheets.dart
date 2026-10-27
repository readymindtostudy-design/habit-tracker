import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'util.dart';
import 'widgets/common.dart';

const List<double> _quickAdd = <double>[0.5, 1, 5];

Widget _sheetHandle() => Center(
      child: Container(
        width: 42,
        height: 4.5,
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );

Widget _sheetTitle(BuildContext context, String title, {Widget? leading}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 6, 10, 10),
    child: Row(
      children: <Widget>[
        if (leading != null) ...<Widget>[leading, const SizedBox(width: 12)],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
        ),
      ],
    ),
  );
}

InputDecoration fieldDecoration(String? hint, {String? suffix}) {
  return InputDecoration(
    hintText: hint,
    suffixText: suffix,
    filled: true,
    fillColor: AppColors.card2,
    hintStyle: const TextStyle(color: AppColors.muted),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
    ),
  );
}

// ------------------------------------------------------------------ log sheet

Future<void> showLogSheet(BuildContext context, Habit habit,
    {String? date}) async {
  final String key = date ?? todayKey();
  final AppState app = context.read<AppState>();
  final TextEditingController controller = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setLocal) {
            final double current = habit.valueOn(key);
            final String sub = habit.isWeekly
                ? '${dayLabel(key)}: ${fmtNumber(current)} ${habit.unit}  •  Week ${fmtNumber(app.weekTotal(habit, app.weekStartFor(parseKey(key))))}/${fmtNumber(habit.target)}'
                : '${dayLabel(key)}: ${fmtNumber(current)} / ${fmtNumber(habit.target)} ${habit.unit}';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sheetHandle(),
                _sheetTitle(
                  ctx,
                  'Log ${habit.name}',
                  leading: IconBubble(
                      icon: habit.icon, color: habit.color, size: 44),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(sub,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.muted)),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    style: const TextStyle(fontSize: 22),
                    decoration: fieldDecoration('0', suffix: habit.unit),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 10,
                    children: _quickAdd
                        .map((double q) => ActionChip(
                              backgroundColor: AppColors.card2,
                              side: BorderSide.none,
                              label: Text('+${fmtNumber(q)}'),
                              onPressed: () {
                                app.logAdd(habit, q, key);
                                setLocal(() {});
                              },
                            ))
                        .toList(),
                  ),
                ),
                if (current > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () {
                        app.logClear(habit, key);
                        setLocal(() {});
                      },
                      child: const Text('Clear this day\u2019s log',
                          style: TextStyle(color: AppColors.danger)),
                    ),
                  ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            side: const BorderSide(color: AppColors.line),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final double v =
                                double.tryParse(controller.text.trim()) ?? 0.0;
                            if (v > 0) app.logAdd(habit, v, key);
                            Navigator.of(ctx).pop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.greenInk,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Log'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

// --------------------------------------------------------------- confirm sheet

Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool danger = true,
}) async {
  final bool? result = await showModalBottomSheet<bool>(
    context: context,
    builder: (BuildContext ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _sheetHandle(),
        _sheetTitle(ctx, title),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Text(message,
              style: const TextStyle(color: AppColors.muted, height: 1.4)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.line),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        danger ? AppColors.danger : AppColors.green,
                    foregroundColor:
                        danger ? Colors.white : AppColors.greenInk,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

// -------------------------------------------------------------- insights sheet

Future<void> showInsightsSheet(BuildContext context) async {
  final AppState app = context.read<AppState>();
  final List<Habit> act = app.activeHabits;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (BuildContext ctx, ScrollController scroll) {
          if (act.isEmpty) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _sheetHandle(),
                _sheetTitle(ctx, 'Insights'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Text('Add a habit to see your stats here.',
                      style: TextStyle(color: AppColors.muted)),
                ),
              ],
            );
          }
          final List<Habit> daily = app.dailyHabits;
          final int doneToday = daily.where(app.doneToday).length;
          double rateSum = 0;
          for (final Habit h in act) {
            rateSum += app.completionRate(h);
          }
          final double avg = rateSum / act.length;
          final List<Habit> ranked = List<Habit>.of(act)
            ..sort((a, b) => app.streak(b).compareTo(app.streak(a)));
          final Habit best = ranked.first;

          return ListView(
            controller: scroll,
            padding: const EdgeInsets.only(bottom: 30),
            children: <Widget>[
              _sheetHandle(),
              _sheetTitle(ctx, 'Insights'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    StatTile(
                        value: '$doneToday/${daily.length}',
                        label: 'Done today'),
                    StatTile(
                        value: '${(avg * 100).round()}%',
                        label: 'Average rate'),
                    StatTile(
                        value: '${app.streak(best)}',
                        label: best.isWeekly
                            ? 'Best streak (wk)'
                            : 'Best streak'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...act.map((Habit h) {
                final double r = app.completionRate(h);
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                  child: Row(
                    children: <Widget>[
                      IconBubble(icon: h.icon, color: h.color, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(h.name,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 6),
                            ProgressBar(value: r, color: hexColor(h.color)),
                            const SizedBox(height: 5),
                            Text(
                              'Streak ${app.streak(h)} • ${h.isWeekly ? 'last 12 weeks' : 'last 30 days'}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${(r * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      );
    },
  );
}

// ---------------------------------------------------------------- backup sheet

Future<void> showBackupSheet(BuildContext context) async {
  final AppState app = context.read<AppState>();
  final TextEditingController controller =
      TextEditingController(text: app.exportJson());

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _sheetHandle(),
            _sheetTitle(ctx, 'Backup'),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Your data lives on this phone. Copy this text somewhere safe, or paste a saved backup and restore it.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  style: const TextStyle(fontSize: 12.5, fontFamily: 'monospace'),
                  decoration: fieldDecoration(null),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final String? err = app.importJson(controller.text);
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        showToast(
                            context,
                            err ??
                                'Backup restored');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Restore'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: controller.text));
                        if (!ctx.mounted) return;
                        showToast(context, 'Backup copied');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.greenInk,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Copy'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// -------------------------------------------------------------- settings sheet

Future<void> showSettingsSheet(BuildContext context) async {
  final AppState app = context.read<AppState>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setLocal) {
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 28),
            children: <Widget>[
              _sheetHandle(),
              _sheetTitle(ctx, 'Settings'),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Week starts on',
                    style: TextStyle(color: AppColors.muted)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: <Widget>[
                    _choice(app.weekStart == 1, 'Monday', () {
                      app.setWeekStart(1);
                      setLocal(() {});
                    }),
                    const SizedBox(width: 10),
                    _choice(app.weekStart == 0, 'Sunday', () {
                      app.setWeekStart(0);
                      setLocal(() {});
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  'Your habits, tasks and timers are saved in this phone\u2019s app storage. Nothing is uploaded. Use Backup before you uninstall.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ),
              const Divider(height: 30),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined,
                    color: AppColors.green),
                title: const Text('Reminders'),
                subtitle: Text(
                  app.notificationsEnabled
                      ? 'On — daily reminders are scheduled'
                      : 'Tap to allow notifications for habit reminders',
                  style: const TextStyle(color: AppColors.muted),
                ),
                onTap: () async {
                  await app.enableReminders();
                  if (ctx.mounted) setLocal(() {});
                  if (context.mounted) {
                    showToast(
                        context,
                        app.notificationsEnabled
                            ? 'Reminders enabled'
                            : 'Notifications not allowed');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined,
                    color: AppColors.green),
                title: const Text('Backup and restore'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showBackupSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined,
                    color: AppColors.green),
                title: const Text('Load sample habits'),
                onTap: () {
                  app.seedSamples();
                  Navigator.of(ctx).pop();
                  showToast(context, 'Sample habits added');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Reset all data',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  final bool ok = await showConfirm(
                    context,
                    title: 'Reset all data?',
                    message:
                        'This deletes every habit, log and task on this device. You can\u2019t undo it.',
                    confirmLabel: 'Reset',
                  );
                  if (ok) {
                    app.resetAll();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _choice(bool selected, String label, VoidCallback onTap) {
  return Expanded(
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.green : AppColors.muted,
        side: BorderSide(
            color: selected ? AppColors.green : AppColors.line, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label),
    ),
  );
}

// --------------------------------------------------------- pomodoro settings

Future<void> showPomoSettingsSheet(BuildContext context) async {
  final AppState app = context.read<AppState>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setLocal) {
          Widget stepper(String label, int value, String unit,
              void Function(int) onChange) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(label)),
                  _stepBtn(Icons.remove, () => onChange(-1)),
                  SizedBox(
                    width: 74,
                    child: Center(
                      child: Text('$value$unit',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  _stepBtn(Icons.add, () => onChange(1)),
                ],
              ),
            );
          }

          Widget toggle(String label, bool value, void Function(bool) onChange) {
            return SwitchListTile(
              value: value,
              onChanged: onChange,
              title: Text(label),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            );
          }

          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 26),
            children: <Widget>[
              _sheetHandle(),
              _sheetTitle(ctx, 'Timer settings'),
              stepper('Short break', app.pomoShort, ' min', (int d) {
                app.setPomo(short: (app.pomoShort + d).clamp(1, 60).toInt());
                setLocal(() {});
              }),
              stepper('Long break', app.pomoLong, ' min', (int d) {
                app.setPomo(long: (app.pomoLong + d).clamp(5, 90).toInt());
                setLocal(() {});
              }),
              stepper('Long break after', app.pomoEvery, ' sessions', (int d) {
                app.setPomo(every: (app.pomoEvery + d).clamp(2, 12).toInt());
                setLocal(() {});
              }),
              toggle('Auto-start next timer', app.pomoAuto, (bool v) {
                app.setPomo(auto: v);
                setLocal(() {});
              }),
              toggle('Sound and vibration', app.pomoSound, (bool v) {
                app.setPomo(sound: v);
                setLocal(() {});
              }),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Text(
                  'Breaks apply to Pomodoro timers. Each timer\u2019s own length is set when you add or edit it.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _stepBtn(IconData icon, VoidCallback onTap) {
  return Material(
    color: AppColors.card2,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(icon, size: 20, color: AppColors.text),
      ),
    ),
  );
}

// ----------------------------------------------------------- manual session

Future<void> showManualSessionSheet(BuildContext context) async {
  final AppState app = context.read<AppState>();
  final TextEditingController controller = TextEditingController();
  FocusTimer timer = app.currentTimer!;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setLocal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sheetHandle(),
                _sheetTitle(ctx, 'Add session'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Timer',
                      style: TextStyle(color: AppColors.muted)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: app.timers
                        .map((FocusTimer t) => FilterPill(
                              label: '${t.icon} ${t.name}',
                              selected: t.id == timer.id,
                              accent: hexColor(t.color),
                              onTap: () {
                                timer = t;
                                setLocal(() {});
                              },
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    style: const TextStyle(fontSize: 22),
                    decoration: fieldDecoration('0', suffix: 'min'),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 10,
                    children: <int>[15, 25, 45, 60]
                        .map((int n) => ActionChip(
                              backgroundColor: AppColors.card2,
                              side: BorderSide.none,
                              label: Text('$n'),
                              onPressed: () {
                                controller.text = '$n';
                                setLocal(() {});
                              },
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            side: const BorderSide(color: AppColors.line),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final double v =
                                double.tryParse(controller.text.trim()) ?? 0.0;
                            if (v > 0) app.logManualSession(timer, v);
                            Navigator.of(ctx).pop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.greenInk,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Add session'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
