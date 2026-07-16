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

  test('food resolution parses catalog nutrition and AI rationale', () {
    final result = FoodResolutionResult.fromJson({
      'mealId': 'meal-1',
      'mealItemId': 'item-1',
      'detectedName': 'potato fry',
      'provider': 'OpenAi',
      'model': 'test-model',
      'suggestions': [
        {
          'foodId': 'food-1',
          'displayName': 'Aloo posto',
          'canonicalName': 'Aloo posto',
          'nutritionPer100Grams': {
            'calories': 155,
            'protein': 3,
            'carbohydrates': 18,
            'fat': 8,
            'fibre': 3
          },
          'confidence': .82,
          'rationale': 'Catalog match',
          'isVerified': false,
          'isUserCreated': false
        }
      ]
    });
    expect(result.suggestions.single.name, 'Aloo posto');
    expect(result.suggestions.single.caloriesPer100g, 155);
    expect(result.suggestions.single.confidence, .82);
    expect(result.suggestions.single.rationale, 'Catalog match');
  });

  test('food resolution parses a reviewable AI estimate', () {
    final result = FoodResolutionResult.fromJson({
      'mealId': 'meal-1',
      'mealItemId': 'item-1',
      'detectedName': 'Pickle',
      'query': 'Pickle',
      'provider': 'OpenAi',
      'suggestions': [],
      'estimate': {
        'name': 'Pickle',
        'description': 'Generic Indian pickle estimate',
        'category': 'Condiment',
        'cuisine': 'General',
        'preparationMethod': 'Mixed',
        'foodState': 'Prepared',
        'nutritionPer100Grams': {
          'calories': 150,
          'protein': 1,
          'carbohydrates': 10,
          'fat': 12,
          'fibre': 2
        },
        'confidence': .55,
        'assumptions': ['Oil and salt assumed'],
        'warning': 'AI estimate',
        'estimateToken': 'protected-token'
      }
    });
    expect(result.estimate?.name, 'Pickle');
    expect(result.estimate?.calories, 150);
    expect(result.estimate?.token, 'protected-token');
  });
}
