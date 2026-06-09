import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TaskCategory {
  medicine('Medicine', '💊', Color(0xFF111827)),
  exercise('Yoga / Exercise', '🧘', Color(0xFF047857)),
  wellness('Wellness', '🍏', Color(0xFFB45309));

  const TaskCategory(this.label, this.emoji, this.color);

  final String label;
  final String emoji;
  final Color color;
}

class CareTask {
  const CareTask({
    required this.id,
    required this.title,
    required this.time,
    required this.category,
    required this.voiceLabel,
  });

  final String id;
  final String title;
  final String time;
  final TaskCategory category;
  final String voiceLabel;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'category': category.name,
      'voiceLabel': voiceLabel,
    };
  }

  static CareTask fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim();
    final title = json['title']?.toString().trim();
    final time = json['time']?.toString().trim();
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      throw const FormatException('Saved task is missing required fields.');
    }
    if (time == null || time.isEmpty) {
      throw const FormatException('Saved task is missing a time.');
    }

    final categoryName = json['category']?.toString();
    final parsedTime = DateFormat('h:mm a').parse(time.toUpperCase());
    return CareTask(
      id: id,
      title: title,
      time: DateFormat('h:mm a').format(parsedTime),
      category: TaskCategory.values.firstWhere(
        (category) => category.name == categoryName,
        orElse: () => TaskCategory.wellness,
      ),
      voiceLabel: (json['voiceLabel'] ?? title).toString(),
    );
  }
}

class TaskStore extends ChangeNotifier {
  static final TaskStore _instance = TaskStore._internal();

  factory TaskStore() => _instance;

  TaskStore._internal();

  static const _historyKey = 'task_completion_history_v1';
  static const _tasksKey = 'care_tasks_v1';
  static const _personNameKey = 'person_name_v1';
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  SharedPreferences? _preferences;
  Map<String, Set<String>> _completedByDate = {};
  String _personName = 'Margaret';

  final List<CareTask> _tasks = [];

  static const List<CareTask> _defaultTasks = [
    CareTask(
      id: 'aspirin',
      title: 'Aspirin',
      time: '8:00 AM',
      category: TaskCategory.medicine,
      voiceLabel: 'Aspirin',
    ),
    CareTask(
      id: 'metformin',
      title: 'Metformin',
      time: '1:00 PM',
      category: TaskCategory.medicine,
      voiceLabel: 'Metformin',
    ),
    CareTask(
      id: 'stretching',
      title: 'Gentle stretching',
      time: '3:00 PM',
      category: TaskCategory.exercise,
      voiceLabel: 'gentle stretching',
    ),
    CareTask(
      id: 'water',
      title: 'Drink water',
      time: '4:30 PM',
      category: TaskCategory.wellness,
      voiceLabel: 'drink water',
    ),
    CareTask(
      id: 'walk',
      title: 'Evening walk',
      time: '6:10 PM',
      category: TaskCategory.wellness,
      voiceLabel: 'evening walk',
    ),
  ];

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    _personName = _preferences?.getString(_personNameKey) ?? 'Margaret';
    _completedByDate = {};

    await _loadTasks();
    await _loadHistory();
  }

  Future<void> _loadTasks() async {
    final savedTasks = _preferences?.getString(_tasksKey);
    if (savedTasks == null || savedTasks.isEmpty) {
      await _restoreDefaultTasks();
      return;
    }

    try {
      final decodedTasks = jsonDecode(savedTasks) as List<dynamic>;
      _tasks
        ..clear()
        ..addAll(
          decodedTasks.map(
            (task) => CareTask.fromJson(task as Map<String, dynamic>),
          ),
        );
      _sortTasks();
    } catch (_) {
      await _restoreDefaultTasks();
    }
  }

  Future<void> _loadHistory() async {
    final saved = _preferences?.getString(_historyKey);
    if (saved == null || saved.isEmpty) return;

    try {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      _completedByDate = decoded.map(
        (date, value) => MapEntry(
          date,
          (value as List<dynamic>).map((item) => item.toString()).toSet(),
        ),
      );
    } catch (_) {
      _completedByDate = {};
      await _saveHistory();
    }
  }

  String get personName => _personName;

  String get personInitial {
    final trimmed = _personName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  List<CareTask> get tasks => List.unmodifiable(_tasks);

  String get todayKey => _dateFormat.format(DateTime.now());

  List<CareTask> tasksForCategory(TaskCategory category) {
    return tasks.where((task) => task.category == category).toList();
  }

  bool isDoneToday(String taskId) {
    return _completedByDate[todayKey]?.contains(taskId) ?? false;
  }

  int get completedTodayCount {
    return _validCompletedCount(todayKey);
  }

  double get todayProgress {
    if (tasks.isEmpty) return 0;
    return completedTodayCount / tasks.length;
  }

  List<CareTask> dueTasksAtTime(String time) {
    return _tasks
        .where((task) => task.time == time && !isDoneToday(task.id))
        .toList();
  }

  Future<void> updatePersonName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _personName) return;
    _personName = trimmed;
    await _preferences?.setString(_personNameKey, _personName);
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    required String time,
    required TaskCategory category,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;
    final normalizedTime = normalizeTime(time);

    final task = CareTask(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      title: trimmedTitle,
      time: normalizedTime,
      category: category,
      voiceLabel: trimmedTitle.toLowerCase(),
    );

    _tasks.add(task);
    _sortTasks();
    await _saveTasks();
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    for (final completed in _completedByDate.values) {
      completed.remove(taskId);
    }
    await _saveTasks();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> markDone(String taskId) async {
    if (!_tasks.any((task) => task.id == taskId)) return;
    final completed = _completedByDate.putIfAbsent(todayKey, () => <String>{});
    if (!completed.add(taskId)) return;
    await _saveHistory();
    notifyListeners();
  }

  Future<void> toggleDone(String taskId) async {
    if (!_tasks.any((task) => task.id == taskId)) return;
    final completed = _completedByDate.putIfAbsent(todayKey, () => <String>{});
    if (!completed.remove(taskId)) completed.add(taskId);
    await _saveHistory();
    notifyListeners();
  }

  List<DayProgress> weeklyProgress() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final dateKey = _dateFormat.format(date);
      final completed = _validCompletedCount(dateKey);
      return DayProgress(
        label: DateFormat('E').format(date),
        completed: completed,
        total: tasks.length,
      );
    });
  }

  String normalizeTime(String time) {
    final parsed = DateFormat('h:mm a').parse(time.toUpperCase());
    return DateFormat('h:mm a').format(parsed);
  }

  Future<void> _restoreDefaultTasks() async {
    _tasks
      ..clear()
      ..addAll(_defaultTasks);
    _sortTasks();
    await _saveTasks();
  }

  Future<void> _saveTasks() async {
    await _preferences?.setString(
      _tasksKey,
      jsonEncode(_tasks.map((task) => task.toJson()).toList()),
    );
  }

  Future<void> _saveHistory() async {
    final encodable = _completedByDate.map(
      (date, taskIds) => MapEntry(date, taskIds.toList()),
    );
    await _preferences?.setString(_historyKey, jsonEncode(encodable));
  }

  void _sortTasks() {
    _tasks.sort((first, second) {
      return _minutesSinceMidnight(
        first.time,
      ).compareTo(_minutesSinceMidnight(second.time));
    });
  }

  int _minutesSinceMidnight(String time) {
    final parsed = DateFormat('h:mm a').parse(time.toUpperCase());
    return parsed.hour * 60 + parsed.minute;
  }

  int _validCompletedCount(String dateKey) {
    final completed = _completedByDate[dateKey];
    if (completed == null) return 0;
    final taskIds = _tasks.map((task) => task.id).toSet();
    return completed.where(taskIds.contains).length;
  }
}

class DayProgress {
  const DayProgress({
    required this.label,
    required this.completed,
    required this.total,
  });

  final String label;
  final int completed;
  final int total;

  double get percent => total == 0 ? 0 : completed / total;
}
