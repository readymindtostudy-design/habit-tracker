import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../sheets.dart';
import '../sheets_timer.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';
import 'dashboard.dart' show timeSlices;

String _fmtClock(int ms) {
  final int s = (ms / 1000).ceil();
  return '${two(s ~/ 60)}:${two(s % 60)}';
}

const Map<String, String> _modeNames = <String, String>{
  'focus': 'Focus',
  'short': 'Short break',
  'long': 'Long break',
};

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _range = 7;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final FocusTimer? timer = app.currentTimer;
    if (timer == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.green));
    }

    final bool isBreak = app.runMode != 'focus';
    final Color color =
        isBreak ? const Color(0xFF5AA0F0) : hexColor(timer.color);
    final String label = app.runMode == 'focus' ? timer.name : _modeNames[app.runMode]!;
    final int remaining = app.remaining;
    final bool running = app.runStatus == 'running';
    final bool fresh = !running && remaining >= app.durationOf(app.runMode);
    final Habit? linked = app.habitById(timer.habitId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              ...app.timers.map((FocusTimer t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterPill(
                      label: '${t.icon} ${t.name}',
                      selected: t.id == timer.id,
                      accent: hexColor(t.color),
                      onTap: () => app.selectTimer(t.id),
                    ),
                  )),
              ActionChip(
                backgroundColor: AppColors.card2,
                side: BorderSide.none,
                avatar: const Icon(Icons.add, size: 18, color: AppColors.green),
                label: const Text('New timer',
                    style: TextStyle(color: AppColors.green)),
                onPressed: () => showTimerEditorSheet(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (timer.pomodoro)
          Row(
            children: <Widget>[
              ...<String>['focus', 'short', 'long'].map((String m) {
                final bool on = app.runMode == m;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => app.setMode(m),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            on ? AppColors.green : AppColors.muted,
                        backgroundColor: on
                            ? AppColors.green.withValues(alpha: 0.08)
                            : null,
                        side: BorderSide(
                            color: on ? AppColors.green : AppColors.line,
                            width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(_modeNames[m]!,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                );
              }),
            ],
          ),
        const SizedBox(height: 24),
        Center(
          child: ProgressRing(
            progress: app.progressFraction,
            color: color,
            size: 260,
            stroke: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _fmtClock(remaining),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w300,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _roundButton(Icons.refresh_rounded, 'Reset', app.resetRun),
            const SizedBox(width: 18),
            Material(
              color: color,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: running ? app.pauseTimer : app.startTimer,
                child: SizedBox(
                  width: 132,
                  height: 56,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppColors.greenInk),
                      const SizedBox(width: 6),
                      Text(
                        running ? 'Pause' : (fresh ? 'Start' : 'Resume'),
                        style: const TextStyle(
                            color: AppColors.greenInk,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            if (timer.pomodoro)
              _roundButton(Icons.skip_next_rounded, 'Skip', app.skipPhase)
            else
              const SizedBox(width: 56),
          ],
        ),
        const SectionHeader(title: 'Timer'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconBubble(icon: timer.icon, color: timer.color, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(timer.name,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          '${timer.minutes} min${timer.pomodoro ? ', breaks ${app.pomoShort} / ${app.pomoLong} min' : ', no breaks'}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        showTimerEditorSheet(context, timer: timer),
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                linked == null
                    ? 'Not linked to a habit yet. Link one so finished sessions count toward it.'
                    : (linked.kind == HabitKind.tick
                        ? 'Each finished session ticks ${linked.name}. Today: ${app.progressText(linked)}'
                        : 'Each finished session adds ${timer.minutes} ${linked.unit == 'hr' ? 'min' : linked.unit} to ${linked.name}. Today: ${app.progressText(linked)}'),
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              if (linked == null) ...<Widget>[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      showManualSessionSheet(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Add a session manually'),
                  ),
                ),
              ],
            ],
          ),
        ),
        SectionHeader(title: 'Where your time goes'),
        Row(
          children: <Widget>[
            _rangeButton('Today', 1),
            const SizedBox(width: 8),
            _rangeButton('7 days', 7),
            const SizedBox(width: 8),
            _rangeButton('30 days', 30),
          ],
        ),
        const SizedBox(height: 14),
        _timeCard(app),
      ],
    );
  }

  Widget _rangeButton(String label, int value) {
    final bool on = _range == value;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _range = value),
        style: OutlinedButton.styleFrom(
          foregroundColor: on ? AppColors.green : AppColors.muted,
          backgroundColor:
              on ? AppColors.green.withValues(alpha: 0.08) : null,
          side: BorderSide(
              color: on ? AppColors.green : AppColors.line, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _timeCard(AppState app) {
    final List<DonutSlice> slices = timeSlices(app, _range);
    final double total =
        slices.fold<double>(0, (double a, DonutSlice s) => a + s.minutes);
    if (total <= 0) {
      return AppCard(
        child: Text('No focus time logged in this period.',
            style: const TextStyle(color: AppColors.muted)),
      );
    }
    return AppCard(
      child: Column(
        children: <Widget>[
          DonutChart(
            slices: slices,
            size: 168,
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
          const SizedBox(height: 14),
          ...slices.map((DonutSlice s) => Padding(
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
                    Expanded(child: Text(s.label)),
                    Text(fmtMinutes(s.minutes),
                        style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Material(
      color: AppColors.card2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: AppColors.text),
          ),
        ),
      ),
    );
  }
}
