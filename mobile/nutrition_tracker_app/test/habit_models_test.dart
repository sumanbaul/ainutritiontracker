import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/features/habits/data/habit_repository.dart';

void main() {
  test('habit summary parses period metrics and daily chart points', () {
    final summary = HabitSummary.fromJson({
      'period': 'weekly',
      'startDate': '2026-07-13',
      'endDate': '2026-07-19',
      'days': [
        {'date': '2026-07-13', 'calories': 1840.5, 'meals': 3}
      ],
      'totalCalories': 1840.5,
      'averageCalories': 262.9,
      'confirmedMeals': 3,
      'hydrationMillilitres': 1750,
      'fastingMinutes': 960,
      'targetCalories': 14000,
      'calorieAdherencePercent': 13.1,
      'currentWeightKg': 74.5,
      'weightChangeKg': -0.5,
    });

    expect(summary.period, 'weekly');
    expect(summary.days.single.calories, 1840.5);
    expect(summary.hydrationMillilitres, 1750);
    expect(summary.fastingMinutes, 960);
    expect(summary.weightChangeKg, -0.5);
  });

  test('reminder parses server TimeOnly values', () {
    final reminder = HabitReminder.fromJson({
      'id': 'a0000000-0000-0000-0000-000000000001',
      'type': 'meal',
      'localTime': '12:30:00',
      'timezone': 'Asia/Kolkata',
      'isEnabled': true,
    });

    expect(reminder.localTime.substring(0, 5), '12:30');
    expect(reminder.isEnabled, isTrue);
  });
}
