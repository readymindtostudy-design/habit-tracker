import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFF0A0A0A);
  static const Color card = Color(0xFF161616);
  static const Color card2 = Color(0xFF1F1F1F);
  static const Color line = Color(0xFF2A2A2A);
  static const Color text = Color(0xFFF1F1F1);
  static const Color muted = Color(0xFF8E8E8E);
  static const Color green = Color(0xFF55C878);
  static const Color greenInk = Color(0xFF04170A);
  static const Color danger = Color(0xFFFF6B6B);
}

/// Palette used when creating habits and timers.
const List<String> kPalette = [
  '#F87880', '#FFA070', '#6AA9FF', '#9B8CFF',
  '#CF80FF', '#7ED6A0', '#5FD3DA', '#FF9070',
];

const List<String> kMorePalette = [
  '#FF7A9C', '#FFB347', '#FFD866', '#B6E36B',
  '#55C878', '#2DD4BF', '#38BDF8', '#818CF8',
  '#C084FC', '#F472B6', '#FB7185', '#F59E0B',
  '#84CC16', '#60A5FA', '#A3A3A3', '#E5E5E5',
];

/// Units offered when creating a measurable habit.
const List<String> kUnits = [
  'hr', 'min', 'km', 'mi', 'pages', 'steps',
  'glasses', 'cups', 'reps', 'times', 'L', 'ml', 'kcal',
];

/// Categories offered when creating a habit.
const List<String> kCategories = [
  'Art', 'Finances', 'Fitness', 'Health', 'Nutrition', 'Social',
  'Study', 'Work', 'Morning', 'Day', 'Evening', 'Other',
];

/// Emoji groups for the icon picker in the wizard.
const List<Map<String, dynamic>> kIconGroups = [
  {'n': 'Health', 'i': ['🏃', '🚶', '🧘', '💪', '🚴', '🏊', '🩺', '😴', '🦷', '💊']},
  {'n': 'Nutrition', 'i': ['🥗', '🥑', '💧', '🍎', '🍵', '☕', '🥛', '🍽️', '🚫🍬', '🥕']},
  {'n': 'Mind', 'i': ['📖', '🧠', '🧩', '✍️', '🎯', '🕯️', '🙏', '🌱', '🎨', '🎵']},
  {'n': 'Study', 'i': ['📚', '📝', '💻', '🧪', '🌍', '🗣️', '🔬', '📐', '🖊️', '📓']},
  {'n': 'Work', 'i': ['💼', '📈', '🗂️', '⏱️', '📊', '✅', '📅', '🧾', '💡', '🖥️']},
  {'n': 'Life', 'i': ['🧹', '🌿', '🐕', '👨‍👩‍👧', '📞', '🛒', '💸', '🌙', '☀️', '🚿']},
];

ThemeData buildAppTheme() {
  final ThemeData base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.green,
      onPrimary: AppColors.greenInk,
      surface: AppColors.card,
      onSurface: AppColors.text,
      error: AppColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.text,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1.2),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.card2,
      contentTextStyle: TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}
