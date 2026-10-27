import 'util.dart';

enum HabitKind { tick, measure }

enum HabitFreq { once, multi, weekly }

HabitKind kindFrom(String s) => s == 'measure' ? HabitKind.measure : HabitKind.tick;
String kindName(HabitKind k) => k == HabitKind.measure ? 'measure' : 'tick';

HabitFreq freqFrom(String s) {
  switch (s) {
    case 'multi':
      return HabitFreq.multi;
    case 'weekly':
      return HabitFreq.weekly;
    default:
      return HabitFreq.once;
  }
}

String freqName(HabitFreq f) {
  switch (f) {
    case HabitFreq.multi:
      return 'multi';
    case HabitFreq.weekly:
      return 'weekly';
    case HabitFreq.once:
      return 'once';
  }
}

class Habit {
  String id;
  String name;
  String icon;
  String color;
  HabitKind kind;
  HabitFreq freq;
  String unit;
  double target;
  List<String> tags;
  List<String> reminders; // "HH:mm" 24-hour
  bool quit;
  bool archived;
  String createdAt; // yyyy-MM-dd
  Map<String, double> logs; // dateKey -> value

  Habit({
    required this.id,
    required this.name,
    this.icon = '🏃',
    this.color = '#55C878',
    this.kind = HabitKind.tick,
    this.freq = HabitFreq.once,
    this.unit = 'times',
    this.target = 1,
    List<String>? tags,
    List<String>? reminders,
    this.quit = false,
    this.archived = false,
    String? createdAt,
    Map<String, double>? logs,
  })  : tags = tags ?? <String>[],
        reminders = reminders ?? <String>[],
        createdAt = createdAt ?? todayKey(),
        logs = logs ?? <String, double>{};

  bool get isWeekly => freq == HabitFreq.weekly;

  /// Value needed to consider the day (or, for weekly habits, the week) done.
  double get goal {
    if (kind == HabitKind.tick) return freq == HabitFreq.multi ? target : 1;
    return target;
  }

  double valueOn(String key) => logs[key] ?? 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'kind': kindName(kind),
        'freq': freqName(freq),
        'unit': unit,
        'target': target,
        'tags': tags,
        'reminders': reminders,
        'quit': quit,
        'archived': archived,
        'createdAt': createdAt,
        'logs': logs,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: (j['id'] ?? newId()).toString(),
        name: (j['name'] ?? '').toString(),
        icon: (j['icon'] ?? '🏃').toString(),
        color: (j['color'] ?? '#55C878').toString(),
        kind: kindFrom((j['kind'] ?? 'tick').toString()),
        freq: freqFrom((j['freq'] ?? 'once').toString()),
        unit: (j['unit'] ?? 'times').toString(),
        target: (j['target'] as num?)?.toDouble() ?? 1.0,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList(),
        reminders: (j['reminders'] as List?)?.map((e) => e.toString()).toList(),
        quit: j['quit'] == true,
        archived: j['archived'] == true,
        createdAt: j['createdAt']?.toString(),
        logs: (j['logs'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      );

  Habit copy() => Habit.fromJson(toJson());
}

class Task {
  String id;
  String text;
  bool done;
  String createdAt;

  Task({
    required this.id,
    required this.text,
    this.done = false,
    String? createdAt,
  }) : createdAt = createdAt ?? todayKey();

  Map<String, dynamic> toJson() =>
      {'id': id, 'text': text, 'done': done, 'createdAt': createdAt};

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: (j['id'] ?? newId()).toString(),
        text: (j['text'] ?? '').toString(),
        done: j['done'] == true,
        createdAt: j['createdAt']?.toString(),
      );
}

class FocusTimer {
  String id;
  String name;
  String icon;
  String color;
  bool pomodoro;
  int minutes;
  String? habitId;

  FocusTimer({
    required this.id,
    required this.name,
    this.icon = '🎯',
    this.color = '#55C878',
    this.pomodoro = false,
    this.minutes = 25,
    this.habitId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'pomodoro': pomodoro,
        'minutes': minutes,
        'habitId': habitId,
      };

  factory FocusTimer.fromJson(Map<String, dynamic> j) => FocusTimer(
        id: (j['id'] ?? newId()).toString(),
        name: (j['name'] ?? 'Timer').toString(),
        icon: (j['icon'] ?? '🎯').toString(),
        color: (j['color'] ?? '#55C878').toString(),
        pomodoro: j['pomodoro'] == true,
        minutes: (j['minutes'] as num?)?.toInt() ?? 25,
        habitId: j['habitId']?.toString(),
      );

  FocusTimer copy() => FocusTimer.fromJson(toJson());
}

/// One day of focus-timer activity.
class PomoDay {
  int sessions;
  double minutes;
  Map<String, double> by; // timerId -> minutes

  PomoDay({this.sessions = 0, this.minutes = 0, Map<String, double>? by})
      : by = by ?? <String, double>{};

  Map<String, dynamic> toJson() =>
      {'sessions': sessions, 'minutes': minutes, 'by': by};

  factory PomoDay.fromJson(Map<String, dynamic> j) => PomoDay(
        sessions: (j['sessions'] as num?)?.toInt() ?? 0,
        minutes: (j['minutes'] as num?)?.toDouble() ?? 0.0,
        by: (j['by'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      );
}
