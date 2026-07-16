class MealReview {
  const MealReview(
      {required this.mealId,
      required this.name,
      required this.status,
      required this.totalCalories,
      required this.totalProtein,
      required this.totalCarbs,
      required this.totalFat,
      required this.totalFibre,
      required this.hasIncompleteNutrition,
      required this.items,
      required this.warnings,
      required this.provider,
      required this.model,
      required this.hasImage});
  final String mealId;
  final String? name;
  final String status;
  final double totalCalories, totalProtein, totalCarbs, totalFat, totalFibre;
  final bool hasIncompleteNutrition;
  final List<MealReviewItem> items;
  final List<String> warnings;
  final String provider;
  final String? model;
  final bool hasImage;
  factory MealReview.fromJson(Map<String, dynamic> json) => MealReview(
      mealId: json['mealId'] as String,
      name: json['name'] as String?,
      status: json['status'] as String,
      totalCalories: _number(json['totalCalories']),
      totalProtein: _number(json['totalProteinGrams']),
      totalCarbs: _number(json['totalCarbohydrateGrams']),
      totalFat: _number(json['totalFatGrams']),
      totalFibre: _number(json['totalFibreGrams']),
      hasIncompleteNutrition: json['hasIncompleteNutrition'] as bool? ?? false,
      items: (json['items'] as List)
          .map((x) =>
              MealReviewItem.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList(),
      warnings: (json['warnings'] as List? ?? const []).cast<String>(),
      provider: json['provider'] as String? ?? 'Unknown',
      model: json['model'] as String?,
      hasImage: json['hasImage'] as bool? ?? false);
}

class MealReviewItem {
  const MealReviewItem(
      {required this.id,
      required this.detectedName,
      required this.foodId,
      required this.grams,
      required this.servingUnit,
      required this.calories,
      required this.protein,
      required this.carbs,
      required this.fat,
      required this.fibre,
      required this.recognitionConfidence,
      required this.nutritionMatchConfidence,
      required this.nutritionMatchState,
      required this.preparationMethod,
      required this.requiresConfirmation,
      required this.warnings});
  final String id, detectedName, servingUnit, preparationMethod;
  final String? foodId;
  final double? grams;
  final double? calories, protein, carbs, fat, fibre;
  final double recognitionConfidence, nutritionMatchConfidence;
  final String nutritionMatchState;
  final bool requiresConfirmation;
  final List<String> warnings;
  factory MealReviewItem.fromJson(Map<String, dynamic> json) => MealReviewItem(
      id: json['id'] as String,
      detectedName: json['detectedName'] as String,
      foodId: json['foodId'] as String?,
      grams: _nullableNumber(json['estimatedGrams']),
      servingUnit: json['estimatedServingUnit'] as String,
      calories: _nullableNumber(json['calories']),
      protein: _nullableNumber(json['proteinGrams']),
      carbs: _nullableNumber(json['carbohydrateGrams']),
      fat: _nullableNumber(json['fatGrams']),
      fibre: _nullableNumber(json['fibreGrams']),
      recognitionConfidence: _number(json['recognitionConfidence']),
      nutritionMatchConfidence: _number(json['nutritionMatchConfidence']),
      nutritionMatchState:
          json['nutritionMatchState'] as String? ?? 'Unresolved',
      preparationMethod: json['preparationMethod'] as String,
      requiresConfirmation: json['requiresConfirmation'] as bool,
      warnings: (json['warnings'] as List? ?? const []).cast<String>());
}

class FoodSearchItem {
  const FoodSearchItem(
      {required this.id,
      required this.name,
      required this.caloriesPer100g,
      this.canonicalName,
      this.proteinPer100g = 0,
      this.carbsPer100g = 0,
      this.fatPer100g = 0,
      this.fibrePer100g = 0,
      this.category = 'PreparedDish',
      this.cuisine = 'General',
      this.preparationMethod = 'Unknown',
      this.foodState = 'Prepared',
      this.isVerified = false,
      this.isUserCreated = false,
      this.isEstimate = false,
      this.confidence = 0,
      this.rationale});
  final String id, name;
  final double caloriesPer100g;
  final String? canonicalName;
  final double proteinPer100g, carbsPer100g, fatPer100g, fibrePer100g;
  final String category, cuisine, preparationMethod, foodState;
  final bool isVerified, isUserCreated, isEstimate;
  final double confidence;
  final String? rationale;
  factory FoodSearchItem.fromJson(Map<String, dynamic> json) {
    final nutrition =
        Map<String, dynamic>.from(json['nutritionPer100Grams'] as Map);
    return FoodSearchItem(
        id: json['id'] as String,
        name: json['displayName'] as String,
        canonicalName: json['canonicalName'] as String?,
        caloriesPer100g: _number(nutrition['calories']),
        proteinPer100g: _number(nutrition['protein']),
        carbsPer100g: _number(nutrition['carbohydrates']),
        fatPer100g: _number(nutrition['fat']),
        fibrePer100g: _number(nutrition['fibre']),
        category: json['category'] as String? ?? 'PreparedDish',
        cuisine: json['cuisine'] as String? ?? 'General',
        preparationMethod: json['preparationMethod'] as String? ?? 'Unknown',
        foodState: json['foodState'] as String? ?? 'Prepared',
        isVerified: json['isVerified'] as bool? ?? false,
        isUserCreated: json['isUserCreated'] as bool? ?? false,
        isEstimate: json['isEstimate'] as bool? ?? false);
  }
}

class FoodResolutionResult {
  const FoodResolutionResult(
      {required this.mealId,
      required this.mealItemId,
      required this.detectedName,
      required this.suggestions,
      required this.query,
      required this.noMatchReason,
      required this.estimate,
      required this.provider,
      required this.model});
  final String mealId, mealItemId, detectedName, query, provider;
  final String? model;
  final String? noMatchReason;
  final AiFoodEstimate? estimate;
  final List<FoodSearchItem> suggestions;
  factory FoodResolutionResult.fromJson(Map<String, dynamic> json) =>
      FoodResolutionResult(
          mealId: json['mealId'] as String,
          mealItemId: json['mealItemId'] as String,
          detectedName: json['detectedName'] as String,
          query: json['query'] as String? ?? json['detectedName'] as String,
          noMatchReason: json['noMatchReason'] as String?,
          estimate: json['estimate'] == null
              ? null
              : AiFoodEstimate.fromJson(
                  Map<String, dynamic>.from(json['estimate'] as Map)),
          provider: json['provider'] as String? ?? 'Unknown',
          model: json['model'] as String?,
          suggestions: (json['suggestions'] as List? ?? const [])
              .map((x) => _foodSearchItemFromResolutionJson(
                  Map<String, dynamic>.from(x as Map)))
              .toList());
}

FoodSearchItem _foodSearchItemFromResolutionJson(Map<String, dynamic> json) {
  final nutrition =
      Map<String, dynamic>.from(json['nutritionPer100Grams'] as Map);
  return FoodSearchItem(
      id: json['foodId'] as String,
      name: json['displayName'] as String,
      canonicalName: json['canonicalName'] as String?,
      caloriesPer100g: _number(nutrition['calories']),
      proteinPer100g: _number(nutrition['protein']),
      carbsPer100g: _number(nutrition['carbohydrates']),
      fatPer100g: _number(nutrition['fat']),
      fibrePer100g: _number(nutrition['fibre']),
      isVerified: json['isVerified'] as bool? ?? false,
      isUserCreated: json['isUserCreated'] as bool? ?? false,
      confidence: _number(json['confidence']),
      rationale: json['rationale'] as String?,
      preparationMethod: 'Unknown');
}

class AiFoodEstimate {
  const AiFoodEstimate(
      {required this.name,
      required this.description,
      required this.category,
      required this.cuisine,
      required this.preparationMethod,
      required this.foodState,
      required this.calories,
      required this.protein,
      required this.carbs,
      required this.fat,
      required this.fibre,
      required this.confidence,
      required this.assumptions,
      required this.warning,
      required this.token});
  final String name,
      category,
      cuisine,
      preparationMethod,
      foodState,
      warning,
      token;
  final String? description;
  final double calories, protein, carbs, fat, fibre, confidence;
  final List<String> assumptions;
  factory AiFoodEstimate.fromJson(Map<String, dynamic> json) {
    final n = Map<String, dynamic>.from(json['nutritionPer100Grams'] as Map);
    return AiFoodEstimate(
        name: json['name'] as String,
        description: json['description'] as String?,
        category: json['category'] as String,
        cuisine: json['cuisine'] as String,
        preparationMethod: json['preparationMethod'] as String,
        foodState: json['foodState'] as String,
        calories: _number(n['calories']),
        protein: _number(n['protein']),
        carbs: _number(n['carbohydrates']),
        fat: _number(n['fat']),
        fibre: _number(n['fibre']),
        confidence: _number(json['confidence']),
        assumptions: (json['assumptions'] as List? ?? const []).cast<String>(),
        warning: json['warning'] as String,
        token: json['estimateToken'] as String);
  }
}

class CustomFoodDraft {
  const CustomFoodDraft(
      {required this.name,
      required this.description,
      required this.calories,
      required this.protein,
      required this.carbs,
      required this.fat,
      required this.fibre});
  final String name, description;
  final double calories, protein, carbs, fat, fibre;
}

class MealCorrection {
  const MealCorrection(
      {required this.type,
      required this.createdAtUtc,
      required this.predictedGrams,
      required this.correctedGrams});
  final String type;
  final DateTime createdAtUtc;
  final double? predictedGrams, correctedGrams;
  factory MealCorrection.fromJson(Map<String, dynamic> json) => MealCorrection(
      type: json['correctionType'] as String,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
      predictedGrams: _nullableNumber(json['predictedGrams']),
      correctedGrams: _nullableNumber(json['correctedGrams']));
}

double _number(Object? value) => (value as num?)?.toDouble() ?? 0;
double? _nullableNumber(Object? value) => (value as num?)?.toDouble();
