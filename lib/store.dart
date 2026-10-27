import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'notifications.dart';
import 'util.dart';

/// Single source of truth for the whole app.
///
/// Everything lives in memory here and is mirrored to the phone's private
/// storage as one JSON blob, so the app works fully offline.
class AppState extends ChangeNotifier {
  static const String _prefsKey = 'habit-tracker-v3';

  List<Habit> habits = <Habit>[];
  List<Task> tasks = <Task>[];
  List<FocusTimer> timers = <FocusTimer>[];
  Map<String, PomoDay> pomoLog = <String, PomoDay>{};

  int weekStart = 1; // 1 = Monday, 0 = Sunday
  int pomoShort = 5;
  int pomoLong = 15;
  int pomoEvery = 4;
  bool pomoAuto = false;
  bool pomoSound = true;
  String? selectedTimerId;

  bool loaded = false;
  bool notificationsEnabled = false;

  // Runtime focus-timer state (not persisted; a running timer restarts on relaunch).
  String runMode = 'focus'; // focus | short | long
  String runStatus = 'idle'; // idle | running | paused
  int remainingMs = 25 * 60000;
  int _runEndAt = 0;
  int runCycle = 0;
  Timer? _ticker;
  Timer? _saveTimer;

  // ---------------------------------------------------------------- lifecycle

  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        _read(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt blob: start clean rather than crash.
      }
    }
    if (timers.isEmpty) {
      timers = <FocusTimer>[
        FocusTimer(
            id: newId(),
            name: 'Focus',
            icon: '🎯',
            color: '#55C878',
            pomodoro: true,
            minutes: 25),
        FocusTimer(
            id: newId(),
            name: 'Meditation',
            icon: '🧘',
            color: '#9B8CFF',
            minutes: 10),
      ];
    }
    selectedTimerId ??= timers.first.id;
    runMode = 'focus';
    runStatus = 'idle';
    remainingMs = durationOf('focus');
    loaded = true;
    await NotificationService.init();
    notifyListeners();
    unawaited(syncNotifications());
  }

  void _read(Map<String, dynamic> j) {
    habits = (j['habits'] as List?)
            ?.map((e) => Habit.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Habit>[];
    tasks = (j['tasks'] as List?)
            ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Task>[];
    timers = (j['timers'] as List?)
            ?.map((e) => FocusTimer.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <FocusTimer>[];
    pomoLog = (j['pomoLog'] as Map?)?.map((k, v) =>
            MapEntry(k.toString(), PomoDay.fromJson(v as Map<String, dynamic>))) ??
        <String, PomoDay>{};
    weekStart = (j['weekStart'] as num?)?.toInt() ?? 1;
    pomoShort = (j['pomoShort'] as num?)?.toInt() ?? 5;
    pomoLong = (j['pomoLong'] as num?)?.toInt() ?? 15;
    pomoEvery = (j['pomoEvery'] as num?)?.toInt() ?? 4;
    pomoAuto = j['pomoAuto'] == true;
    pomoSound = j['pomoSound'] != false;
    selectedTimerId = j['selectedTimerId']?.toString();
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'habits': habits.map((h) => h.toJson()).toList(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'timers': timers.map((t) => t.toJson()).toList(),
        'pomoLog': pomoLog.map((k, v) => MapEntry(k, v.toJson())),
        'weekStart': weekStart,
        'pomoShort': pomoShort,
        'pomoLong': pomoLong,
        'pomoEvery': pomoEvery,
        'pomoAuto': pomoAuto,
        'pomoSound': pomoSound,
        'selectedTimerId': selectedTimerId,
      };

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 200), () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(toMap()));
    });
  }

  // ------------------------------------------------------------------ lookups

  Habit? habitById(String? id) {
    if (id == null) return null;
    for (final Habit h in habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  List<Habit> get activeHabits =>
      habits.where((h) => !h.archived).toList(growable: false);

  List<Habit> get dailyHabits =>
      activeHabits.where((h) => !h.isWeekly).toList(growable: false);

  List<Habit> get weeklyHabits =>
      activeHabits.where((h) => h.isWeekly).toList(growable: false);

  List<Task> get openTasks =>
      tasks.where((t) => !t.done).toList(growable: false);

  FocusTimer? get currentTimer {
    if (timers.isEmpty) return null;
    for (final FocusTimer t in timers) {
      if (t.id == selectedTimerId) return t;
    }
    return timers.first;
  }

  bool get hasAnyReminder =>
      activeHabits.any((h) => h.reminders.isNotEmpty);

  // ------------------------------------------------------------- date helpers

  DateTime weekStartFor(DateTime d) {
    final DateTime x = DateTime(d.year, d.month, d.day);
    final int diff = (x.weekday % 7 - weekStart + 7) % 7;
    return x.subtract(Duration(days: diff));
  }

  double weekTotal(Habit h, DateTime ws) {
    double t = 0;
    for (int i = 0; i < 7; i++) {
      final double v = h.valueOn(dateKey(ws.add(Duration(days: i))));
      t += h.kind == HabitKind.tick ? (v >= 1 ? 1 : 0) : v;
    }
    return (t * 100).round() / 100;
  }

  bool dayMet(Habit h, String key) => h.valueOn(key) >= h.goal;

  bool doneToday(Habit h) {
    if (h.isWeekly) {
      return weekTotal(h, weekStartFor(DateTime.now())) >= h.target;
    }
    return dayMet(h, todayKey());
  }

  double todayProgress(Habit h) {
    if (h.isWeekly) {
      final double wt = weekTotal(h, weekStartFor(DateTime.now()));
      return h.target <= 0 ? 0.0 : (wt / h.target).clamp(0, 1).toDouble();
    }
    final double goal = h.goal;
    return goal <= 0 ? 0.0 : (h.valueOn(todayKey()) / goal).clamp(0, 1).toDouble();
  }

  int streak(Habit h) {
    const int maxIter = 1200;
    if (h.isWeekly) {
      int n = 0;
      DateTime ws = weekStartFor(DateTime.now());
      for (int i = 0; i < maxIter; i++) {
        if (dateKey(ws).compareTo(h.createdAt) < 0) break;
        if (weekTotal(h, ws) >= h.target) {
          n++;
          ws = ws.subtract(const Duration(days: 7));
        } else {
          break;
        }
      }
      return n;
    }
    int n = 0;
    DateTime d = DateTime.now();
    if (!dayMet(h, dateKey(d))) {
      d = d.subtract(const Duration(days: 1));
    }
    for (int i = 0; i < maxIter; i++) {
      final String k = dateKey(d);
      if (k.compareTo(h.createdAt) < 0) break;
      if (dayMet(h, k)) {
        n++;
        d = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return n;
  }

  /// Fraction of the last 30 days (or weeks) in which the goal was met.
  double completionRate(Habit h) {
    if (h.isWeekly) {
      int met = 0;
      DateTime ws = weekStartFor(DateTime.now());
      for (int i = 0; i < 12; i++) {
        if (weekTotal(h, ws) >= h.target) met++;
        ws = ws.subtract(const Duration(days: 7));
      }
      return met / 12;
    }
    int met = 0;
    DateTime d = DateTime.now();
    for (int i = 0; i < 30; i++) {
      if (dayMet(h, dateKey(d))) met++;
      d = d.subtract(const Duration(days: 1));
    }
    return met / 30;
  }

  String progressText(Habit h) {
    if (h.isWeekly) {
      final double wt = weekTotal(h, weekStartFor(DateTime.now()));
      return '${fmtNumber(wt)} / ${fmtNumber(h.target)} ${h.unit} this week';
    }
    final double v = h.valueOn(todayKey());
    if (h.kind == HabitKind.tick) {
      if (h.freq == HabitFreq.multi) {
        return '${fmtNumber(v)} / ${fmtNumber(h.goal)} times today';
      }
      return v >= 1 ? 'Done today' : 'Not done yet';
    }
    return '${fmtNumber(v)} / ${fmtNumber(h.target)} ${h.unit} today';
  }

  /// Every upcoming reminder today, sorted by time.
  List<MapEntry<String, Habit>> upcomingReminders() {
    final String nowT =
        '${two(DateTime.now().hour)}:${two(DateTime.now().minute)}';
    final List<MapEntry<String, Habit>> out = <MapEntry<String, Habit>>[];
    for (final Habit h in activeHabits) {
      for (final String t in h.reminders) {
        if (t.compareTo(nowT) > 0) out.add(MapEntry<String, Habit>(t, h));
      }
    }
    out.sort((a, b) => a.key.compareTo(b.key));
    return out;
  }

  // --------------------------------------------------------------- habit CRUD

  void addHabit(Habit h) {
    habits.add(h);
    _afterChange();
  }

  void updateHabit(Habit h) {
    final int i = habits.indexWhere((x) => x.id == h.id);
    if (i >= 0) habits[i] = h;
    _afterChange();
  }

  void deleteHabit(String id) {
    habits.removeWhere((h) => h.id == id);
    for (final FocusTimer t in timers) {
      if (t.habitId == id) t.habitId = null;
    }
    _afterChange();
  }

  void setArchived(Habit h, bool archived) {
    h.archived = archived;
    _afterChange();
  }

  // ------------------------------------------------------------- habit logging

  void logAdd(Habit h, double amount, String key) {
    final double next = (h.logs[key] ?? 0.0) + amount;
    if (next <= 0) {
      h.logs.remove(key);
    } else {
      h.logs[key] = next;
    }
    _afterChange();
  }

  void logSet(Habit h, double value, String key) {
    if (value <= 0) {
      h.logs.remove(key);
    } else {
      h.logs[key] = value;
    }
    _afterChange();
  }

  void logClear(Habit h, String key) {
    h.logs.remove(key);
    _afterChange();
  }

  /// Ticks a tick-habit for the day, or clears it if already done.
  void toggleTick(Habit h, String key) {
    if (h.valueOn(key) >= h.goal) {
      h.logs.remove(key);
    } else {
      h.logs[key] = h.goal;
    }
    _afterChange();
  }

  // ------------------------------------------------------------------ tasks

  void addTask(String text) {
    final String t = text.trim();
    if (t.isEmpty) return;
    tasks.insert(0, Task(id: newId(), text: t));
    _afterChange();
  }

  void toggleTask(Task t) {
    t.done = !t.done;
    _afterChange();
  }

  void deleteTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    _afterChange();
  }

  // ------------------------------------------------------------------ focus

  int durationOf(String mode) {
    switch (mode) {
      case 'short':
        return pomoShort * 60000;
      case 'long':
        return pomoLong * 60000;
      default:
        return (currentTimer?.minutes ?? 25) * 60000;
    }
  }

  int get remaining {
    if (runStatus == 'running') {
      final int r = _runEndAt - DateTime.now().millisecondsSinceEpoch;
      return r < 0 ? 0 : r;
    }
    return remainingMs;
  }

  double get progressFraction {
    final int total = durationOf(runMode);
    if (total <= 0) return 0;
    return (1 - remaining / total).clamp(0, 1).toDouble();
  }

  void selectTimer(String id) {
    if (runStatus == 'running') return;
    selectedTimerId = id;
    runMode = 'focus';
    runStatus = 'idle';
    remainingMs = durationOf('focus');
    _afterChange();
  }

  void setMode(String mode) {
    if (runStatus == 'running') return;
    runMode = mode;
    runStatus = 'idle';
    remainingMs = durationOf(mode);
    _afterChange();
  }

  void startTimer() {
    runStatus = 'running';
    _runEndAt = DateTime.now().millisecondsSinceEpoch + remainingMs;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pauseTimer() {
    remainingMs = remaining;
    runStatus = 'paused';
    _ticker?.cancel();
    notifyListeners();
  }

  void resetRun() {
    _ticker?.cancel();
    runMode = 'focus';
    runStatus = 'idle';
    _runEndAt = 0;
    remainingMs = durationOf('focus');
    notifyListeners();
  }

  /// Skips to the next phase without crediting the session.
  void skipPhase() {
    _ticker?.cancel();
    final FocusTimer? t = currentTimer;
    if (t != null && t.pomodoro) {
      runCycle += 1;
      runMode = runMode == 'focus'
          ? (runCycle % pomoEvery == 0 ? 'long' : 'short')
          : 'focus';
    } else {
      runMode = 'focus';
    }
    runStatus = 'idle';
    _runEndAt = 0;
    remainingMs = durationOf(runMode);
    _afterChange();
  }

  void _tick() {
    if (remaining <= 0) {
      _complete();
    } else {
      notifyListeners();
    }
  }

  void _complete() {
    _ticker?.cancel();
    final FocusTimer? t = currentTimer;
    if (t != null) {
      _creditSession(t, t.minutes.toDouble());
    }
    if (t != null && t.pomodoro) {
      runCycle += 1;
      runMode = runMode == 'focus'
          ? (runCycle % pomoEvery == 0 ? 'long' : 'short')
          : 'focus';
    } else {
      runMode = 'focus';
    }
    runStatus = 'idle';
    _runEndAt = 0;
    remainingMs = durationOf(runMode);
    _save();
    notifyListeners();
    if (pomoAuto) startTimer();
  }

  /// Adds a manually entered focus session.
  void logManualSession(FocusTimer t, double minutes) {
    if (minutes <= 0) return;
    _creditSession(t, minutes);
    _save();
    notifyListeners();
  }

  void _creditSession(FocusTimer t, double minutes) {
    final String key = todayKey();
    final PomoDay day = pomoLog.putIfAbsent(key, () => PomoDay());
    day.sessions += 1;
    day.minutes += minutes;
    day.by[t.id] = (day.by[t.id] ?? 0.0) + minutes;

    final Habit? h = habitById(t.habitId);
    if (h != null) {
      if (h.kind == HabitKind.tick) {
        h.logs[key] = (h.logs[key] ?? 0.0) + 1;
      } else {
        final double add = h.unit == 'hr' ? minutes / 60 : minutes;
        h.logs[key] = (h.logs[key] ?? 0.0) + add;
      }
    }
  }

  // ---------------------------------------------------------------- timers CRUD

  void saveTimer(FocusTimer t) {
    final int i = timers.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      timers[i] = t;
    } else {
      timers.add(t);
      selectedTimerId = t.id;
    }
    if (selectedTimerId == null) selectedTimerId = timers.first.id;
    _afterChange();
  }

  void deleteTimer(String id) {
    if (timers.length <= 1) return;
    timers.removeWhere((t) => t.id == id);
    if (selectedTimerId == id) selectedTimerId = timers.first.id;
    _afterChange();
  }

  // ------------------------------------------------------------------ settings

  void setWeekStart(int value) {
    weekStart = value;
    _afterChange();
  }

  void setPomo({int? short, int? long, int? every, bool? auto, bool? sound}) {
    if (short != null) pomoShort = short;
    if (long != null) pomoLong = long;
    if (every != null) pomoEvery = every;
    if (auto != null) pomoAuto = auto;
    if (sound != null) pomoSound = sound;
    _afterChange();
  }

  // --------------------------------------------------------------- reminders

  Future<void> enableReminders() async {
    final bool granted = await NotificationService.requestPermission();
    notificationsEnabled = granted;
    notifyListeners();
    await syncNotifications();
  }

  /// Re-creates every scheduled reminder from the current habits.
  Future<void> syncNotifications() async {
    try {
      await NotificationService.cancelAll();
      for (final Habit h in activeHabits) {
        for (int i = 0; i < h.reminders.length; i++) {
          final List<String> parts = h.reminders[i].split(':');
          if (parts.length != 2) continue;
          await NotificationService.scheduleDaily(
            id: _notificationId(h.id, i),
            title: h.quit ? 'Stay on track' : 'Time for ${h.name}',
            body: h.quit
                ? 'Keep going with ${h.name} today.'
                : 'A quick nudge to log ${h.name}.',
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
    } catch (_) {
      // Reminders are best-effort; never block the app on them.
    }
  }

  int _notificationId(String habitId, int index) {
    final int base = habitId.hashCode.abs() % 100000;
    return base * 10 + (index % 10);
  }

  // --------------------------------------------------------------- bulk data

  void resetAll() {
    habits = <Habit>[];
    tasks = <Task>[];
    pomoLog = <String, PomoDay>{};
    _afterChange();
  }

  String exportJson() => jsonEncode(toMap());

  /// Returns null on success, or an error message.
  String? importJson(String raw) {
    try {
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      _read(j);
      selectedTimerId ??= timers.isEmpty ? null : timers.first.id;
      _afterChange();
      return null;
    } catch (_) {
      return 'That does not look like a valid backup.';
    }
  }

  void seedSamples() {
    final DateTime now = DateTime.now();
    Habit mk(String name, String icon, String color, HabitKind kind,
        HabitFreq freq, String unit, double target, List<String> tags,
        List<String> reminders, int salt) {
      final Habit h = Habit(
        id: newId(),
        name: name,
        icon: icon,
        color: color,
        kind: kind,
        freq: freq,
        unit: unit,
        target: target,
        tags: tags,
        reminders: reminders,
        createdAt: dateKey(now.subtract(const Duration(days: 20))),
      );
      for (int i = 0; i < 20; i++) {
        final DateTime d = now.subtract(Duration(days: i));
        final double r =
            (DateTime(d.year, d.month, d.day).millisecondsSinceEpoch %
                        (salt * 977 + 31))
                    .abs() %
                100 /
            100;
        if (kind == HabitKind.tick) {
          if (r > 0.28) h.logs[dateKey(d)] = h.goal;
        } else {
          final double v = (target * (0.6 + r * 0.6));
          if (v > 0) h.logs[dateKey(d)] = (v * 10).round() / 10;
        }
      }
      return h;
    }

    habits.addAll(<Habit>[
      mk('Meditate', '🧘', '#9B8CFF', HabitKind.tick, HabitFreq.once, 'times',
          1, <String>['Health', 'Morning'], <String>['07:30'], 3),
      mk('Read', '📖', '#6AA9FF', HabitKind.measure, HabitFreq.once, 'pages',
          20, <String>['Study'], <String>['21:00'], 7),
      mk('Walk', '🚶', '#55C878', HabitKind.measure, HabitFreq.once, 'km', 5,
          <String>['Fitness'], <String>['18:30'], 11),
      mk('Drink water', '💧', '#5FD3DA', HabitKind.tick, HabitFreq.multi,
          'times', 8, <String>['Health'], <String>[], 13),
      mk('Gym', '💪', '#FFA070', HabitKind.tick, HabitFreq.weekly, 'times', 4,
          <String>['Fitness'], <String>[], 17),
    ]);
    _afterChange();
  }

  // ---------------------------------------------------------------- internals

  void _afterChange() {
    _save();
    unawaited(syncNotifications());
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}
