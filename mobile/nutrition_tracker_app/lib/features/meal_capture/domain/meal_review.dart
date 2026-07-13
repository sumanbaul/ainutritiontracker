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
      {required this.id, required this.name, required this.caloriesPer100g});
  final String id, name;
  final double caloriesPer100g;
  factory FoodSearchItem.fromJson(Map<String, dynamic> json) {
    final nutrition =
        Map<String, dynamic>.from(json['nutritionPer100Grams'] as Map);
    return FoodSearchItem(
        id: json['id'] as String,
        name: json['displayName'] as String,
        caloriesPer100g: _number(nutrition['calories']));
  }
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
