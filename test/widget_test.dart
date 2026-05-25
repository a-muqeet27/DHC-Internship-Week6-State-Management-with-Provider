import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_management_app_week6/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('adds a task and updates the completion summary', (tester) async {
    await tester.pumpWidget(const TaskApp());
    await tester.pumpAndSettle();

    expect(find.text('0 of 0 tasks completed'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_task));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Write provider tests');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Write provider tests'), findsOneWidget);
    expect(find.text('0 of 1 tasks completed'), findsOneWidget);
  });

  testWidgets('toggles and edits a task using Provider-driven UI updates', (tester) async {
    await tester.pumpWidget(const TaskApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_task));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Draft report');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('1 of 1 tasks completed'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Draft final report');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Draft final report'), findsOneWidget);
  });
}
