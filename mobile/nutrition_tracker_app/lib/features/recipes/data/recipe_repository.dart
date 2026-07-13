import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/local_database.dart';
import '../../meal_capture/domain/meal_review.dart';

class RecipeSummary {
  const RecipeSummary(
      {required this.id,
      required this.name,
      required this.servings,
      required this.caloriesPerServing,
      required this.ingredients,
      required this.version});
  final String id, name;
  final double servings, caloriesPerServing;
  final int version;
  final List<Map<String, dynamic>> ingredients;
  factory RecipeSummary.fromJson(Map<String, dynamic> json) => RecipeSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      servings: (json['servingCount'] as num).toDouble(),
      caloriesPerServing: (json['caloriesPerServing'] as num).toDouble(),
      ingredients: (json['ingredients'] as List)
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList(),
      version: (json['version'] as num?)?.toInt() ?? 0);
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'servingCount': servings,
        'caloriesPerServing': caloriesPerServing,
        'ingredients': ingredients,
        'version': version
      };
}

class RecipeRepository {
  RecipeRepository(this._api, this._db);
  final ApiClient _api;
  final LocalDatabase _db;
  static const cacheKey = 'recipes.cache.v1';
  Future<Result<List<RecipeSummary>>> list({bool refresh = false}) async {
    if (!refresh) {
      final cached = await _db.readSetting(cacheKey);
      if (cached != null) {
        return Success((jsonDecode(cached) as List)
            .map((x) =>
                RecipeSummary.fromJson(Map<String, dynamic>.from(x as Map)))
            .toList());
      }
    }
    try {
      final response = await _api.get('/api/recipes');
      final values = (response.data as List)
          .map((x) =>
              RecipeSummary.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList();
      await _db.saveSetting(
          cacheKey, jsonEncode(values.map((x) => x.toJson()).toList()));
      return Success(values);
    } catch (_) {
      final cached = await _db.readSetting(cacheKey);
      return cached == null
          ? const Failure(AppFailure('Recipes are unavailable.'))
          : Success((jsonDecode(cached) as List)
              .map((x) =>
                  RecipeSummary.fromJson(Map<String, dynamic>.from(x as Map)))
              .toList());
    }
  }

  Future<Result<MealReview>> createMeal(
      RecipeSummary recipe, double servings) async {
    try {
      final response = await _api.post('/api/meals/manual/recipe', data: {
        'recipeId': recipe.id,
        'servings': servings,
        'mealType': 'Unknown',
        'consumedAtUtc': DateTime.now().toUtc().toIso8601String()
      });
      return Success(
          MealReview.fromJson(Map<String, dynamic>.from(response.data as Map)));
    } catch (_) {
      return const Failure(AppFailure('Recipe meal could not be created.'));
    }
  }
}

final recipeRepositoryProvider = Provider((ref) => RecipeRepository(
    ref.watch(apiClientProvider), ref.watch(localDatabaseProvider)));
