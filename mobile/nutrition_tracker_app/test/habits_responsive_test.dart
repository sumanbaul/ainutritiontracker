import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/app/theme/app_theme.dart';
import 'package:nutrition_tracker_app/core/networking/api_client.dart';
import 'package:nutrition_tracker_app/core/result/result.dart';
import 'package:nutrition_tracker_app/features/habits/data/habit_repository.dart';
import 'package:nutrition_tracker_app/features/habits/presentation/habits_page.dart';

class _HabitRepository extends HabitRepository {
  _HabitRepository() : super(ApiClient(Dio()));

  @override
  Future<Result<HabitSummary>> summary(String period) async => Success(
        HabitSummary(
          period: period,
          startDate: DateTime(2026, 7, 13),
          endDate: DateTime(2026, 7, 13),
          days: const [],
          totalCalories: 0,
          averageCalories: 0,
          confirmedMeals: 0,
          hydrationMillilitres: 1250,
          fastingMinutes: 720,
        ),
      );

  @override
  Future<Result<List<HabitReminder>>> reminders() async =>
      const Success(<HabitReminder>[]);
}

void main() {
  testWidgets('habit actions remain constrained on a narrow large-text screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        habitRepositoryProvider.overrideWithValue(_HabitRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(
              size: Size(320, 760), textScaler: TextScaler.linear(1.3)),
          child: HabitsPage(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('250 ml'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
