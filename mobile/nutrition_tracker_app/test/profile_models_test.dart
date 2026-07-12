import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/features/profile/domain/profile.dart';

void main() {
  test('profile and nutrition target parse backend decimals safely', () {
    final profile = UserProfile.fromJson({
      'name': 'Suman',
      'dateOfBirth': '1990-09-26',
      'biologicalSex': 'Male',
      'currentWeightKg': 75,
      'targetWeightKg': 70.5,
      'heightCm': 170.18,
      'age': 35,
      'activityLevel': 'ModeratelyActive',
      'goalType': 'LoseWeightSlowly',
      'dietPreference': 'NonVegetarian',
      'preferredMeasurementSystem': 'Metric',
      'timezone': 'Asia/Kolkata',
      'currentNutritionTarget': {
        'targetCalories': 2050,
        'proteinGrams': 120.5,
        'carbohydrateGrams': 230,
        'fatGrams': 68,
        'fibreGrams': 30,
        'basalMetabolicRate': 1640,
        'totalDailyEnergyExpenditure': 2540
      }
    });
    expect(profile.target.calories, 2050);
    expect(profile.height, 170.18);
    expect(profile.target.bmr, 1640);
  });
}
