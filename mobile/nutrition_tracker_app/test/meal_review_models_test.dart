import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/features/meal_capture/domain/meal_review.dart';

void main() {
  test('meal review parses backend draft totals and warnings', () {
    final review = MealReview.fromJson({
      'mealId': '00000000-0000-0000-0000-000000000001',
      'name': 'Lunch',
      'status': 'AwaitingReview',
      'totalCalories': 420,
      'totalProteinGrams': 22,
      'totalCarbohydrateGrams': 60,
      'totalFatGrams': 10,
      'totalFibreGrams': 6,
      'warnings': ['Confirm portion'],
      'provider': 'OpenAi',
      'hasImage': true,
      'items': [
        {
          'id': '00000000-0000-0000-0000-000000000002',
          'foodId': null,
          'detectedName': 'Rice',
          'estimatedGrams': 150,
          'estimatedServingUnit': 'gram',
          'calories': 195,
          'proteinGrams': 4,
          'carbohydrateGrams': 42,
          'fatGrams': 1,
          'fibreGrams': 1,
          'preparationMethod': 'Unknown',
          'requiresConfirmation': true,
          'warnings': []
        }
      ]
    });
    expect(review.mealId, '00000000-0000-0000-0000-000000000001');
    expect(review.items.single.grams, 150);
    expect(review.warnings.single, 'Confirm portion');
    expect(review.provider, 'OpenAi');
    expect(review.hasImage, isTrue);
  });
}
