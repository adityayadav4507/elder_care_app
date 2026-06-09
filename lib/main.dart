import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'services/alarm_service.dart';
import 'services/task_store.dart';

// 1. Create a Global Key so the alarm can show a popup from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TaskStore().init();
  runApp(const ElderCareApp());
}

class ElderCareApp extends StatefulWidget {
  const ElderCareApp({super.key});

  @override
  State<ElderCareApp> createState() => _ElderCareAppState();
}

class _ElderCareAppState extends State<ElderCareApp> {
  final AlarmService _alarmService = AlarmService();

  @override
  void initState() {
    super.initState();
    // 2. Start checking the clock as soon as the app opens
    _alarmService.startClock(navigatorKey);
  }

  @override
  void dispose() {
    _alarmService.stopClock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 3. Attach the key to your app
      title: 'Elder Care Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}
