import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../sheets.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';

/// Four-step flow for creating or editing a habit.
class HabitWizard extends StatefulWidget {
  const HabitWizard({super.key, this.existing});

  final Habit? existing;

  static Future<void> open(BuildContext context, {Habit? existing}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => HabitWizard(existing: existing),
      ),
    );
  }

  @override
  State<HabitWizard> createState() => _HabitWizardState();
}

class _HabitWizardState extends State<HabitWizard> {
  late Habit _draft;
  late int _step;
  bool _kindChosen = false;
  String? _error;
  String _cat = 'Health';
  bool _allColors = false;
  final List<String> _extraTags = <String>[];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _customUnitController = TextEditingController();
  bool _customUnit = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing?.copy() ??
        Habit(id: newId(), name: '', icon: '🏃', color: '#F87880');
    _kindChosen = _editing;
    _step = _editing ? 2 : 1;
    _nameController.text = _draft.name;
    if (_draft.kind == HabitKind.measure) {
      _targetController.text = fmtNumber(_draft.target);
      if (!kUnits.contains(_draft.unit)) {
        _customUnit = true;
        _customUnitController.text = _draft.unit;
      }
    } else if (_draft.freq != HabitFreq.once) {
      _targetController.text = fmtNumber(_draft.target);
    }
    for (final Map<String, dynamic> g in kIconGroups) {
      if ((g['i'] as List).contains(_draft.icon)) {
        _cat = g['n'] as String;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _customUnitController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  String get _unit =>
      _customUnit ? _customUnitController.text.trim() : _draft.unit;

  bool get _canContinue {
    switch (_step) {
      case 1:
        return _kindChosen;
      case 2:
        return _nameController.text.trim().isNotEmpty;
      case 3:
        if (_draft.kind == HabitKind.measure) {
          return _unit.isNotEmpty &&
              (double.tryParse(_targetController.text.trim()) ?? 0) > 0;
        }
        if (_draft.freq == HabitFreq.once) return true;
        return (int.tryParse(_targetController.text.trim()) ?? 0) >= 1;
      default:
        return true;
    }
  }

  void _next() {
    setState(() {
      _error = null;
      if (_step == 2) {
        _draft.name = _nameController.text.trim();
      }
      if (_step == 3) {
        if (_draft.kind == HabitKind.measure) {
          _draft.unit = _unit;
          _draft.target =
              double.tryParse(_targetController.text.trim()) ?? _draft.target;
        } else if (_draft.freq != HabitFreq.once) {
          _draft.target =
              double.tryParse(_targetController.text.trim()) ?? _draft.target;
        }
      }
      if (_step < 4) {
        _step += 1;
      } else {
        _save();
      }
    });
  }

  void _save() {
    final AppState app = context.read<AppState>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState nav = Navigator.of(context);
    _draft.name = _nameController.text.trim();
    if (_editing) {
      app.updateHabit(_draft);
    } else {
      app.addHabit(_draft);
    }
    nav.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(_editing ? 'Habit updated' : 'Habit created'),
        duration: const Duration(milliseconds: 1800),
        margin: const EdgeInsets.all(16),
      ));
  }

  void _back() {
    if (_step <= (_editing ? 2 : 1)) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 12, 0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: _back,
                    icon: Icon(_step <= (_editing ? 2 : 1)
                        ? Icons.close_rounded
                        : Icons.arrow_back_rounded),
                    tooltip: 'Back',
                  ),
                  const Spacer(),
                  Text(
                    _editing ? 'Edit habit' : 'New habit',
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Row(
                children: List<Widget>.generate(4, (int i) {
                  final bool on = _step >= i + 1;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: on ? AppColors.green : AppColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: _body(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 18),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canContinue ? _next : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.greenInk,
                    disabledBackgroundColor: AppColors.card2,
                    disabledForegroundColor: AppColors.muted,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                  child: Text(_step == 4
                      ? (_editing ? 'Save changes' : 'Save habit')
                      : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case 1:
        return _stepKind();
      case 2:
        return _stepName();
      case 3:
        return _stepTrack();
      default:
        return _stepRemind();
    }
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(t,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      );

  Widget _errorText() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(_error!,
              style: const TextStyle(color: AppColors.danger)),
        );

  // ------------------------------------------------------------------ step 1

  Widget _stepKind() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('What kind of habit?'),
        _kindOption(
          kind: HabitKind.tick,
          title: 'Tick',
          subtitle: 'Track yes or no per day',
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: 12),
        _kindOption(
          kind: HabitKind.measure,
          title: 'Measurable',
          subtitle: 'Track numbers, distance, or time',
          icon: Icons.bar_chart_rounded,
        ),
        if (_kindChosen && _draft.kind == HabitKind.tick) ...<Widget>[
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _quitChoice(false, 'Build a Habit', Icons.trending_up_rounded),
              const SizedBox(width: 10),
              _quitChoice(true, 'Quit a Habit', Icons.block),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _draft.quit
                ? 'Break a habit you want to leave behind. Tick each day you stay clear of it.'
                : 'Add a new positive routine. Daily completions build your streak.',
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ],
        _errorText(),
      ],
    );
  }

  Widget _kindOption({
    required HabitKind kind,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool on = _kindChosen && _draft.kind == kind;
    return Material(
      color: on ? AppColors.green.withValues(alpha: 0.08) : AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() {
          _draft.kind = kind;
          _kindChosen = true;
          if (kind == HabitKind.measure) {
            _draft.freq = _draft.freq == HabitFreq.multi
                ? HabitFreq.once
                : _draft.freq;
          }
        }),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: on ? AppColors.green : AppColors.line, width: 1.6),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon,
                  size: 28, color: on ? AppColors.green : AppColors.muted),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13.5, color: AppColors.muted)),
                  ],
                ),
              ),
              Icon(
                on ? Icons.check_circle : Icons.circle_outlined,
                color: on ? AppColors.green : AppColors.line,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quitChoice(bool quit, String label, IconData icon) {
    final bool on = _draft.quit == quit;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _draft.quit = quit),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: on ? AppColors.green : AppColors.muted,
          side: BorderSide(
              color: on ? AppColors.green : AppColors.line, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ step 2

  Widget _stepName() {
    final List<String> groups = kIconGroups
        .map((Map<String, dynamic> g) => g['n'] as String)
        .toList();
    final List<String> icons =
        ((kIconGroups.firstWhere((Map<String, dynamic> g) => g['n'] == _cat)
                as Map<String, dynamic>)['i'] as List)
            .map((dynamic e) => e.toString())
            .toList();
    final List<String> colors = <String>[
      ...kPalette,
      if (_allColors) ...kMorePalette,
    ];
    if (!colors.contains(_draft.color)) colors.insert(0, _draft.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Name your habit'),
        Center(
          child: Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint(_draft.color, 0.28),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: tint(_draft.color, 0.28),
                    blurRadius: 34,
                    spreadRadius: 2),
              ],
            ),
            child: Text(_draft.icon, style: const TextStyle(fontSize: 42)),
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _nameController,
          maxLength: 40,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
          decoration: InputDecoration(
            hintText: 'e.g. Morning run, Read books',
            counterText: '',
            filled: true,
            fillColor: AppColors.card2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.green, width: 1.5),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 22),
        const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: groups
                .map((String g) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterPill(
                        label: g,
                        selected: _cat == g,
                        onTap: () => setState(() => _cat = g),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: icons.map((String ic) {
            final bool on = _draft.icon == ic;
            return Material(
              color: on ? tint(_draft.color, 0.3) : AppColors.card2,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _draft.icon = ic),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: on ? hexColor(_draft.color) : Colors.transparent,
                        width: 1.6),
                  ),
                  child: Text(ic, style: const TextStyle(fontSize: 24)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        const Text('Colour', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((String c) {
            final bool on =
                _draft.color.toLowerCase() == c.toLowerCase();
            return GestureDetector(
              onTap: () => setState(() => _draft.color = c),
              child: Container(
                width: 40,
                height: 40,
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
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _allColors = !_allColors),
          style: TextButton.styleFrom(foregroundColor: AppColors.green),
          child: Text(_allColors ? 'Show fewer' : 'See all'),
        ),
        _errorText(),
      ],
    );
  }

  // ------------------------------------------------------------------ step 3

  Widget _stepTrack() {
    final bool tick = _draft.kind == HabitKind.tick;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('How do you track it?'),
        const Text('Repeat goal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (tick)
          Row(
            children: <Widget>[
              Expanded(child: _freqButton(HabitFreq.once, 'Once a day')),
              const SizedBox(width: 8),
              Expanded(child: _freqButton(HabitFreq.multi, 'Multiple a day')),
            ],
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _freqButton(HabitFreq.weekly, 'Weekly goal'),
        ),
        if (tick && _draft.freq == HabitFreq.multi) ...<Widget>[
          const SizedBox(height: 18),
          const Text('Times per day',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          TextField(
            controller: _targetController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20),
            decoration: fieldDecoration('e.g. 8'),
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (tick && _draft.freq == HabitFreq.weekly) ...<Widget>[
          const SizedBox(height: 18),
          const Text('Days per week',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          TextField(
            controller: _targetController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20),
            decoration: fieldDecoration('e.g. 4'),
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (!tick) ...<Widget>[
          const SizedBox(height: 18),
          const Text('Unit', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ...kUnits.map((String u) => FilterPill(
                    label: u,
                    selected: !_customUnit && _draft.unit == u,
                    onTap: () => setState(() {
                      _customUnit = false;
                      _draft.unit = u;
                    }),
                  )),
              FilterPill(
                label: 'Custom',
                selected: _customUnit,
                onTap: () => setState(() => _customUnit = true),
              ),
            ],
          ),
          if (_customUnit) ...<Widget>[
            const SizedBox(height: 10),
            TextField(
              controller: _customUnitController,
              maxLength: 16,
              decoration: fieldDecoration('e.g. laps, chapters, cups'),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 14),
          Text(_draft.freq == HabitFreq.weekly
              ? 'Target per week'
              : 'Target per day'),
          const SizedBox(height: 8),
          TextField(
            controller: _targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 20),
            decoration:
                fieldDecoration('0', suffix: _unit.isEmpty ? 'unit' : _unit),
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 24),
        const Text('Categories',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ...kCategories.map((String c) {
              final bool on = _draft.tags.contains(c);
              return FilterPill(
                label: c,
                selected: on,
                onTap: () => setState(() {
                  if (on) {
                    _draft.tags.remove(c);
                  } else {
                    _draft.tags.add(c);
                  }
                }),
              );
            }),
            ..._extraTags.map((String c) {
              final bool on = _draft.tags.contains(c);
              return FilterPill(
                label: c,
                selected: on,
                onTap: () => setState(() {
                  if (on) {
                    _draft.tags.remove(c);
                  } else {
                    _draft.tags.add(c);
                  }
                }),
              );
            }),
          ],
        ),
        const SizedBox(height: 10),
        _addTagField(),
        _errorText(),
      ],
    );
  }

  Widget _addTagField() {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _tagController,
            maxLength: 16,
            decoration: fieldDecoration('Add a category'),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            final String v = _tagController.text.trim();
            if (v.isEmpty) return;
            setState(() {
              if (!kCategories.contains(v) && !_extraTags.contains(v)) {
                _extraTags.add(v);
              }
              if (!_draft.tags.contains(v)) _draft.tags.add(v);
              _tagController.clear();
            });
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.card2,
            foregroundColor: AppColors.text,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _freqButton(HabitFreq f, String label) {
    final bool on = _draft.freq == f;
    return OutlinedButton(
      onPressed: () => setState(() {
        _draft.freq = f;
        if (_draft.kind == HabitKind.tick &&
            _targetController.text.trim().isEmpty) {
          _targetController.text = f == HabitFreq.weekly ? '4' : '2';
        }
      }),
      style: OutlinedButton.styleFrom(
        foregroundColor: on ? AppColors.green : AppColors.muted,
        side: BorderSide(
            color: on ? AppColors.green : AppColors.line, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13.5)),
    );
  }

  // ------------------------------------------------------------------ step 4

  Widget _stepRemind() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _title('Set a daily reminder')),
            Switch(
              value: _draft.reminders.isNotEmpty,
              onChanged: (bool v) async {
                if (v) {
                  await _addReminder();
                } else {
                  setState(() => _draft.reminders.clear());
                }
              },
            ),
          ],
        ),
        const Text(
          'A nudge at the right time makes it easier to show up. These fire as real notifications, even when the app is closed.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ..._draft.reminders.map((String t) => Chip(
                  backgroundColor: AppColors.card2,
                  side: BorderSide.none,
                  label: Text(fmtTime(t)),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () =>
                      setState(() => _draft.reminders.remove(t)),
                )),
            ActionChip(
              backgroundColor: AppColors.green.withValues(alpha: 0.12),
              side: BorderSide.none,
              avatar: const Icon(Icons.add, size: 18, color: AppColors.green),
              label: const Text('Add time',
                  style: TextStyle(color: AppColors.green)),
              onPressed: _addReminder,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Reminders are saved with the habit and re-scheduled automatically whenever you change anything.',
          style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
        ),
      ],
    );
  }

  Future<void> _addReminder() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    final String t = '${two(picked.hour)}:${two(picked.minute)}';
    setState(() {
      if (!_draft.reminders.contains(t)) {
        _draft.reminders.add(t);
        _draft.reminders.sort();
      }
    });
  }
}
