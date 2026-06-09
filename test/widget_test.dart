import 'package:elder_care_app/main.dart';
import 'package:elder_care_app/services/task_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the daily elder care task screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await TaskStore().init();

    await tester.pumpWidget(const ElderCareApp());
    await tester.pump();

    expect(find.text('Margaret'), findsOneWidget);
    expect(find.text("Today's Progress"), findsOneWidget);
    expect(find.text('Add alarm'), findsOneWidget);
    expect(find.text('Alarm name'), findsOneWidget);
  });
}
