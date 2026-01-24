import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/services/workout_service.dart';
import 'package:resistance_app/widgets/workout_controls.dart';

void main() {
  group('WorkoutControls Widget', () {
    late bool startCalled;
    late bool pauseCalled;
    late bool resumeCalled;
    late bool restartCalled;
    late bool finishCalled;

    setUp(() {
      startCalled = false;
      pauseCalled = false;
      resumeCalled = false;
      restartCalled = false;
      finishCalled = false;
    });

    Widget buildWidget(WorkoutState state) {
      return MaterialApp(
        home: Scaffold(
          body: WorkoutControls(
            workoutState: state,
            onStart: () => startCalled = true,
            onPause: () => pauseCalled = true,
            onResume: () => resumeCalled = true,
            onRestart: () => restartCalled = true,
            onFinish: () => finishCalled = true,
          ),
        ),
      );
    }

    group('Idle State', () {
      testWidgets('shows Start button', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.idle));
        expect(find.text('Start'), findsOneWidget);
      });

      testWidgets('does not show Pause button', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.idle));
        expect(find.text('Pause'), findsNothing);
      });

      testWidgets('calls onStart when Start is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.idle));

        await tester.tap(find.text('Start'));
        await tester.pump();

        expect(startCalled, isTrue);
      });
    });

    group('Active State', () {
      testWidgets('shows only Pause button', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.active));

        expect(find.text('Pause'), findsOneWidget);
        expect(find.text('Finish'), findsNothing); // Finish only shows when paused
      });

      testWidgets('does not show Start button', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.active));
        expect(find.text('Start'), findsNothing);
      });

      testWidgets('calls onPause when Pause is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.active));

        await tester.tap(find.text('Pause'));
        await tester.pump();

        expect(pauseCalled, isTrue);
      });
    });

    group('Paused State', () {
      testWidgets('shows Resume, Restart, and Finish buttons', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.paused));

        expect(find.text('Resume'), findsOneWidget);
        expect(find.text('Restart'), findsOneWidget);
        expect(find.text('Finish'), findsOneWidget);
      });

      testWidgets('calls onResume when Resume is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.paused));

        await tester.tap(find.text('Resume'));
        await tester.pump();

        expect(resumeCalled, isTrue);
      });

      testWidgets('calls onRestart when Restart is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.paused));

        await tester.tap(find.text('Restart'));
        await tester.pump();

        expect(restartCalled, isTrue);
      });

      testWidgets('calls onFinish when Finish is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.paused));

        await tester.tap(find.text('Finish'));
        await tester.pump();

        expect(finishCalled, isTrue);
      });
    });

    group('Finished State', () {
      testWidgets('shows no buttons', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.finished));

        expect(find.text('Start'), findsNothing);
        expect(find.text('Pause'), findsNothing);
        expect(find.text('Resume'), findsNothing);
        expect(find.text('Restart'), findsNothing);
        expect(find.text('Finish'), findsNothing);
      });
    });
  });
}
