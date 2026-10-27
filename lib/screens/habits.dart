import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../sheets.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';
import 'wizard.dart';

enum _HabitTab { measure, tick, weekly }

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  _HabitTab _tab = _HabitTab.measure;
  String? _filter;
  bool _showArchived = false;

  bool _inTab(Habit h, _HabitTab t) {
    if (h.isWeekly) return t == _HabitTab.weekly;
    if (t == _HabitTab.weekly) return false;
    return t == _HabitTab.tick
        ? h.kind == HabitKind.tick
        : h.kind == HabitKind.measure;
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final List<Habit> live = app.habits
        .where((Habit h) => !h.archived && _inTab(h, _tab))
        .toList();
    final List<Habit> archived = app.habits
        .where((Habit h) => h.archived && _inTab(h, _tab))
        .toList();

    final List<String> tags = <String>[];
    for (final Habit h in live) {
      for (final String t in h.tags) {
        if (!tags.contains(t)) tags.add(t);
      }
    }
    if (_filter != null && !tags.contains(_filter)) _filter = null;

    final List<Habit> shown = _filter == null
        ? live
        : live.where((Habit h) => h.tags.contains(_filter)).toList();

    final String emptyMsg = <_HabitTab, String>{
      _HabitTab.measure:
          'Tap + and choose Measurable to track numbers, distance, or time.',
      _HabitTab.tick:
          'Tap + and choose Tick to track a simple yes or no each day.',
      _HabitTab.weekly:
          'Tap + and pick a weekly goal to set a target for the whole week.',
    }[_tab]!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
      children: <Widget>[
        Row(
          children: <Widget>[
            _tabButton('Measurable', _HabitTab.measure),
            const SizedBox(width: 8),
            _tabButton('Tick', _HabitTab.tick),
            const SizedBox(width: 8),
            _tabButton('Weekly', _HabitTab.weekly),
          ],
        ),
        if (tags.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                FilterPill(
                  label: 'All',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                ...tags.map((String t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterPill(
                        label: t,
                        selected: _filter == t,
                        onTap: () => setState(
                            () => _filter = _filter == t ? null : t),
                      ),
                    )),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text(emptyMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.5)),
          )
        else
          ...shown.map((Habit h) => HabitCard(
                habit: h,
                onTap: () => showLogSheet(context, h),
                onAction: () {
                  if (h.kind == HabitKind.tick) {
                    app.toggleTick(h, todayKey());
                  } else {
                    showLogSheet(context, h);
                  }
                },
                onMenu: () => _menu(context, h),
              )),
        if (archived.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _showArchived = !_showArchived),
            icon: Icon(_showArchived
                ? Icons.expand_less
                : Icons.expand_more),
            label: Text('Archived (${archived.length})'),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
          ),
          if (_showArchived)
            ...archived.map((Habit h) => Opacity(
                  opacity: 0.6,
                  child: HabitCard(
                    habit: h,
                    onTap: () => showLogSheet(context, h),
                    onAction: () {},
                    onMenu: () => _menu(context, h),
                  ),
                )),
        ],
      ],
    );
  }

  Widget _tabButton(String label, _HabitTab tab) {
    final bool on = _tab == tab;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() {
          _tab = tab;
          _filter = null;
        }),
        style: OutlinedButton.styleFrom(
          foregroundColor: on ? AppColors.green : AppColors.muted,
          backgroundColor:
              on ? AppColors.green.withValues(alpha: 0.08) : null,
          side: BorderSide(
              color: on ? AppColors.green : AppColors.line, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Future<void> _menu(BuildContext context, Habit h) async {
    final AppState app = context.read<AppState>();
    final String? action = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _sheetHandle(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
            ListTile(
              leading: Icon(h.archived ? Icons.unarchive : Icons.archive),
              title: Text(h.archived ? 'Unarchive' : 'Archive'),
              onTap: () => Navigator.of(ctx).pop('archive'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Delete',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      HabitWizard.open(context, existing: h);
    } else if (action == 'archive') {
      app.setArchived(h, !h.archived);
    } else if (action == 'delete') {
      final bool ok = await showConfirm(
        context,
        title: 'Delete ${h.name}?',
        message:
            'This removes the habit and all of its logged progress. You can\u2019t undo it. To keep the history, archive it instead.',
      );
      if (ok) app.deleteHabit(h.id);
    }
  }
}

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
