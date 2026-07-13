import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/features/recipes/data/recipe_repository.dart';

void main() {
  test('recipe response retains servings nutrition ingredients and version',
      () {
    final recipe = RecipeSummary.fromJson({
      'id': 'r1',
      'name': 'Khichuri',
      'servingCount': 4,
      'caloriesPerServing': 320.5,
      'version': 3,
      'ingredients': [
        {'foodId': 'f1', 'food': 'Rice', 'grams': 200}
      ]
    });
    expect(recipe.name, 'Khichuri');
    expect(recipe.servings, 4);
    expect(recipe.caloriesPerServing, 320.5);
    expect(recipe.version, 3);
    expect(recipe.ingredients.single['food'], 'Rice');
  });
}
