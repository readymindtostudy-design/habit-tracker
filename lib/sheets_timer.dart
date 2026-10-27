import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'sheets.dart';
import 'store.dart';
import 'theme.dart';
import 'util.dart';
import 'widgets/common.dart';

const List<String> _timerIcons = <String>[
  '🎯', '📚', '🧘', '💻', '🎨', '🏋️', '✍️', '🎵', '🧠', '⏱️',
];

/// Create or edit a focus timer.
Future<void> showTimerEditorSheet(BuildContext context,
    {FocusTimer? timer}) async {
  final AppState app = context.read<AppState>();
  final FocusTimer draft = timer?.copy() ??
      FocusTimer(id: newId(), name: '', icon: '🎯', color: '#55C878', minutes: 25);
  final TextEditingController nameC =
      TextEditingController(text: draft.name);
  final TextEditingController minC =
      TextEditingController(text: '${draft.minutes}');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setLocal) {
            final List<Habit> eligible = app.activeHabits
                .where((Habit h) =>
                    h.kind == HabitKind.tick ||
                    h.unit == 'min' ||
                    h.unit == 'hr')
                .toList();

            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 26),
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4.5,
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 10, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          timer == null ? 'New timer' : 'Edit timer',
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Name', style: TextStyle(color: AppColors.muted)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: nameC,
                    maxLength: 30,
                    decoration: fieldDecoration('e.g. Study, Reading'),
                    onChanged: (_) => setLocal(() {}),
                  ),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Icon', style: TextStyle(color: AppColors.muted)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timerIcons.map((String ic) {
                      final bool on = draft.icon == ic;
                      return Material(
                        color: on ? tint(draft.color, 0.3) : AppColors.card2,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setLocal(() => draft.icon = ic),
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: on
                                      ? hexColor(draft.color)
                                      : Colors.transparent,
                                  width: 1.6),
                            ),
                            child: Text(ic,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Colour',
                      style: TextStyle(color: AppColors.muted)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: kPalette.map((String c) {
                      final bool on =
                          draft.color.toLowerCase() == c.toLowerCase();
                      return GestureDetector(
                        onTap: () => setLocal(() => draft.color = c),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: hexColor(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: on ? AppColors.text : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: draft.pomodoro,
                  onChanged: (bool v) => setLocal(() => draft.pomodoro = v),
                  title: const Text('Pomodoro with breaks'),
                  subtitle: const Text(
                    'Adds short and long breaks between focus sessions',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 6, 20, 8),
                  child: Text('Length (minutes)',
                      style: TextStyle(color: AppColors.muted)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: minC,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: fieldDecoration('25', suffix: 'min'),
                  ),
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Count toward a habit',
                      style: TextStyle(color: AppColors.muted)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: eligible.isEmpty
                      ? const Text(
                          'You have no habit that can track time yet. Create one measured in minutes first, or leave this unlinked.',
                          style: TextStyle(
                              color: AppColors.muted, height: 1.4),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            FilterPill(
                              label: 'None',
                              selected: draft.habitId == null,
                              onTap: () =>
                                  setLocal(() => draft.habitId = null),
                            ),
                            ...eligible.map((Habit h) => FilterPill(
                                  label: '${h.icon} ${h.name}',
                                  selected: draft.habitId == h.id,
                                  onTap: () =>
                                      setLocal(() => draft.habitId = h.id),
                                )),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: <Widget>[
                      if (timer != null && app.timers.length > 1)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              final bool ok = await showConfirm(
                                context,
                                title: 'Delete ${timer.name}?',
                                message:
                                    'The timer is removed. Time you already tracked stays in your totals.',
                              );
                              if (ok) app.deleteTimer(timer.id);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                      if (timer != null && app.timers.length > 1)
                        const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            draft.name = nameC.text.trim();
                            if (draft.name.isEmpty) {
                              draft.name = 'Timer';
                            }
                            draft.minutes =
                                (int.tryParse(minC.text.trim()) ?? 25)
                                    .clamp(1, 180)
                                    .toInt();
                            app.saveTimer(draft);
                            Navigator.of(ctx).pop();
                            showToast(context,
                                timer == null ? 'Timer added' : 'Timer saved');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.greenInk,
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(timer == null ? 'Add timer' : 'Save'),
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
