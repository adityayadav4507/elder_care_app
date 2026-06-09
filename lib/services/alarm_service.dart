import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:intl/intl.dart';

import 'task_store.dart';

class AlarmService {
  // Make this a Singleton so we don't create multiple timers
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterTts flutterTts = FlutterTts();
  final TaskStore _taskStore = TaskStore();
  bool isRinging = false;
  Timer? _timer;
  String? _lastCheckedMinute;
  List<String> _activeTaskIds = [];

  void startClock(GlobalKey<NavigatorState> navigatorKey) {
    _timer?.cancel();
    _checkForDueTask(navigatorKey);
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkForDueTask(navigatorKey),
    );
  }

  void stopClock() {
    _timer?.cancel();
    _timer = null;
  }

  void _checkForDueTask(GlobalKey<NavigatorState> navigatorKey) {
    if (isRinging) return;

    final now = DateTime.now();
    final minuteKey = DateFormat('yyyy-MM-dd h:mm a').format(now);
    if (_lastCheckedMinute == minuteKey) return;
    _lastCheckedMinute = minuteKey;

    final formattedTime = DateFormat('h:mm a').format(now);
    final tasks = _taskStore.dueTasksAtTime(formattedTime);
    if (tasks.isEmpty) return;

    triggerAlarm(
      navigatorKey,
      tasks.map((task) => task.voiceLabel).join(', '),
      formattedTime,
      taskIds: tasks.map((task) => task.id).toList(),
    );
  }

  Future<void> triggerAlarm(
    GlobalKey<NavigatorState> navigatorKey,
    String taskName,
    String time, {
    String? taskId,
    List<String>? taskIds,
  }) async {
    isRinging = true;
    _activeTaskIds = taskIds ?? [if (taskId != null) taskId];

    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [500, 900, 500, 900, 500, 900], repeat: 1);
      }
    } catch (_) {
      // Vibration is not available on every Flutter target.
    }

    try {
      await _useIndianWomanVoice();
      await flutterTts.setSpeechRate(0.36);
      await flutterTts.setPitch(1.05);
      await flutterTts.speak(
        "Hello ${_taskStore.personName}, it is $time. Time for your $taskName.",
      );
    } catch (_) {
      // Text-to-speech is best-effort so the visual alarm still appears.
    }

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Alarm",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            content: Text(
              "${_taskStore.personName}, time for:\n$taskName\n$time",
              style: const TextStyle(fontSize: 22),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Stop Alarm",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                onPressed: () async {
                  final dialogNavigator = Navigator.of(context);
                  await stopAlarm();
                  dialogNavigator.pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> stopAlarm() async {
    final taskIds = List<String>.from(_activeTaskIds);
    isRinging = false;
    _activeTaskIds = [];

    try {
      Vibration.cancel();
    } catch (_) {}

    try {
      await flutterTts.stop();
    } catch (_) {}

    for (final taskId in taskIds) {
      await _taskStore.markDone(taskId);
    }
  }

  Future<void> _useIndianWomanVoice() async {
    await flutterTts.setLanguage("en-IN");

    final voices = await flutterTts.getVoices;
    if (voices is! List) return;

    for (final voice in voices) {
      if (voice is! Map) continue;
      final locale = voice['locale']?.toString().toLowerCase() ?? '';
      final name = voice['name']?.toString().toLowerCase() ?? '';
      if (!locale.contains('en-in')) continue;

      final soundsFemale =
          name.contains('female') ||
          name.contains('woman') ||
          name.contains('raveena') ||
          name.contains('aditi') ||
          name.contains('heera');
      if (!soundsFemale) continue;

      await flutterTts.setVoice({
        'name': voice['name'].toString(),
        'locale': voice['locale'].toString(),
      });
      return;
    }
  }
}
