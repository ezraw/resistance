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
        expect(find.text('START'), findsOneWidget);
      });

      testWidgets('does not show Pause button', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.idle));
        expect(find.text('PAUSE'), findsNothing);
      });

      testWidgets('calls onStart when Start is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.idle));

        await tester.tap(find.text('START'));
        await tester.pump();

        expect(startCalled, isTrue);
      });
    });

    group('Active State', () {
      testWidgets('shows only Pause button', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.active));

        expect(find.text('PAUSE'), findsOneWidget);
        expect(find.text('FINISH'), findsNothing);
      });

      testWidgets('does not show Start button', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.active));
        expect(find.text('START'), findsNothing);
      });

      testWidgets('calls onPause when Pause is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.active));

        await tester.tap(find.text('PAUSE'));
        await tester.pump();

        expect(pauseCalled, isTrue);
      });
    });

    group('Paused State', () {
      testWidgets('shows Resume, Restart, and Finish buttons', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.paused));

        expect(find.text('RESUME'), findsOneWidget);
        expect(find.text('RESTART'), findsOneWidget);
        expect(find.text('FINISH'), findsOneWidget);
      });

      testWidgets('calls onResume when Resume is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.paused));

        await tester.tap(find.text('RESUME'));
        await tester.pump();

        expect(resumeCalled, isTrue);
      });

      testWidgets('calls onRestart when Restart is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.paused));

        await tester.tap(find.text('RESTART'));
        await tester.pump();

        expect(restartCalled, isTrue);
      });

      testWidgets('calls onFinish when Finish is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.paused));

        await tester.tap(find.text('FINISH'));
        await tester.pump();

        expect(finishCalled, isTrue);
      });
    });

    group('Finished State', () {
      testWidgets('shows no buttons', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(WorkoutState.finished));

        expect(find.text('START'), findsNothing);
        expect(find.text('PAUSE'), findsNothing);
        expect(find.text('RESUME'), findsNothing);
        expect(find.text('RESTART'), findsNothing);
        expect(find.text('FINISH'), findsNothing);
      });
    });
  });
}
