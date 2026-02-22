import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/services/workout_service.dart';
import 'package:resistance_app/widgets/workout_controls.dart';

void main() {
  group('WorkoutControls HISTORY button', () {
    late bool historyCalled;

    setUp(() {
      historyCalled = false;
    });

    Widget buildWidget(WorkoutState state, {VoidCallback? onHistory}) {
      return MaterialApp(
        home: Scaffold(
          body: WorkoutControls(
            workoutState: state,
            onStart: () {},
            onPause: () {},
            onResume: () {},
            onRestart: () {},
            onFinish: () {},
            onHistory: onHistory,
          ),
        ),
      );
    }

    testWidgets('HISTORY button visible in idle state when onHistory is provided', (tester) async {
      await tester.pumpWidget(buildWidget(WorkoutState.idle, onHistory: () => historyCalled = true));
      expect(find.text('HISTORY'), findsOneWidget);
    });

    testWidgets('HISTORY button absent in idle state when onHistory is null', (tester) async {
      await tester.pumpWidget(buildWidget(WorkoutState.idle));
      expect(find.text('HISTORY'), findsNothing);
    });

    testWidgets('HISTORY button absent in active state', (tester) async {
      await tester.pumpWidget(buildWidget(WorkoutState.active, onHistory: () => historyCalled = true));
      expect(find.text('HISTORY'), findsNothing);
    });

    testWidgets('HISTORY button absent in paused state', (tester) async {
      await tester.pumpWidget(buildWidget(WorkoutState.paused, onHistory: () => historyCalled = true));
      expect(find.text('HISTORY'), findsNothing);
    });

    testWidgets('HISTORY callback fires on tap', (tester) async {
      await tester.pumpWidget(buildWidget(WorkoutState.idle, onHistory: () => historyCalled = true));
      await tester.tap(find.text('HISTORY'));
      await tester.pump();
      expect(historyCalled, isTrue);
    });

    testWidgets('START button still works alongside HISTORY', (tester) async {
      var startCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WorkoutControls(
            workoutState: WorkoutState.idle,
            onStart: () => startCalled = true,
            onPause: () {},
            onResume: () {},
            onRestart: () {},
            onFinish: () {},
            onHistory: () => historyCalled = true,
          ),
        ),
      ));

      expect(find.text('START'), findsOneWidget);
      expect(find.text('HISTORY'), findsOneWidget);

      await tester.tap(find.text('START'));
      await tester.pump();
      expect(startCalled, isTrue);
    });
  });
}
