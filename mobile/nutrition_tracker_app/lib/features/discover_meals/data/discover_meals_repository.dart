import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/local_database.dart';

class DiscoverRecipe {
  const DiscoverRecipe({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.calories,
    required this.protein,
    required this.preparationMinutes,
    required this.ingredients,
    required this.preparation,
  });
  final String id, name, cuisine;
  final double calories, protein;
  final int preparationMinutes;
  final List<Map<String, dynamic>> ingredients;
  final List<String> preparation;

  factory DiscoverRecipe.fromJson(Map<String, dynamic> json) => DiscoverRecipe(
      id: json['id'] as String,
      name: json['name'] as String,
      cuisine: json['cuisine'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['proteinGrams'] as num).toDouble(),
      preparationMinutes: json['preparationMinutes'] as int,
      ingredients: (json['ingredients'] as List)
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList(),
      preparation: (json['preparation'] as List).cast<String>());
}

class PlannedDiscoverMeal {
  const PlannedDiscoverMeal(
      {required this.date,
      required this.slot,
      required this.recipe,
      required this.saved});
  final DateTime date;
  final String slot;
  final DiscoverRecipe recipe;
  final bool saved;
  factory PlannedDiscoverMeal.fromJson(
          DateTime date, Map<String, dynamic> json) =>
      PlannedDiscoverMeal(
          date: date,
          slot: json['slot'] as String,
          recipe: DiscoverRecipe.fromJson(
              Map<String, dynamic>.from(json['recipe'] as Map)),
          saved: json['isSaved'] as bool? ?? false);
}

class DiscoverPlan {
  const DiscoverPlan(
      {required this.startDate, required this.meals, required this.disclaimer});
  final DateTime startDate;
  final List<PlannedDiscoverMeal> meals;
  final String disclaimer;
  factory DiscoverPlan.fromJson(Map<String, dynamic> json) {
    final meals = <PlannedDiscoverMeal>[];
    for (final day in json['days'] as List) {
      final map = Map<String, dynamic>.from(day as Map);
      final date = DateTime.parse(map['date'] as String);
      for (final meal in map['meals'] as List) {
        meals.add(PlannedDiscoverMeal.fromJson(
            date, Map<String, dynamic>.from(meal as Map)));
      }
    }
    return DiscoverPlan(
        startDate: DateTime.parse(json['startDate'] as String),
        meals: meals,
        disclaimer: json['disclaimer'] as String);
  }
}

class DiscoverMealsRepository {
  DiscoverMealsRepository(this._api, this._db);
  final ApiClient _api;
  final LocalDatabase _db;
  static const _cacheKey = 'discover-meals.plan.v1';

  Future<Result<DiscoverPlan>> plan({bool refresh = false}) async {
    if (!refresh) {
      final cached = await _db.readSetting(_cacheKey);
      if (cached != null) {
        return Success(DiscoverPlan.fromJson(jsonDecode(cached)));
      }
    }
    try {
      final response = await _api.get('/api/discover-meals/recommendations');
      final json = Map<String, dynamic>.from(response.data as Map);
      await _db.saveSetting(_cacheKey, jsonEncode(json));
      return Success(DiscoverPlan.fromJson(json));
    } catch (_) {
      final cached = await _db.readSetting(_cacheKey);
      return cached == null
          ? const Failure(AppFailure('Discover Meals is unavailable.'))
          : Success(DiscoverPlan.fromJson(jsonDecode(cached)));
    }
  }

  Future<Result<DiscoverPlan>> regenerate() async {
    try {
      final response = await _api.post('/api/discover-meals/plan/regenerate');
      final json = Map<String, dynamic>.from(response.data as Map);
      await _db.saveSetting(_cacheKey, jsonEncode(json));
      return Success(DiscoverPlan.fromJson(json));
    } catch (_) {
      return const Failure(AppFailure('A new plan could not be generated.'));
    }
  }

  Future<Result<void>> save(String recipeId) async {
    try {
      await _api.put('/api/discover-meals/saved/$recipeId');
      return const Success(null);
    } catch (_) {
      return const Failure(AppFailure('Recipe could not be saved.'));
    }
  }

  Future<Result<void>> addPlanToShopping() async {
    try {
      await _api.post('/api/discover-meals/shopping-list/from-plan');
      return const Success(null);
    } catch (_) {
      return const Failure(AppFailure('Shopping list could not be updated.'));
    }
  }

  Future<Result<List<String>>> exclusions() async {
    try {
      final response = await _api.get('/api/dietary-preferences');
      return Success((response.data as List)
          .map((item) => (item as Map)['code'] as String)
          .toList());
    } catch (_) {
      return const Failure(AppFailure('Dietary exclusions are unavailable.'));
    }
  }

  Future<Result<void>> saveExclusions(Iterable<String> values) async {
    try {
      await _api.put('/api/dietary-preferences',
          data: values
              .where((value) => value.trim().isNotEmpty)
              .map((value) => {'code': value.trim().toLowerCase()})
              .toList());
      return const Success(null);
    } catch (_) {
      return const Failure(
          AppFailure('Dietary exclusions could not be saved.'));
    }
  }
}

final discoverMealsRepositoryProvider = Provider((ref) =>
    DiscoverMealsRepository(
        ref.watch(apiClientProvider), ref.watch(localDatabaseProvider)));
