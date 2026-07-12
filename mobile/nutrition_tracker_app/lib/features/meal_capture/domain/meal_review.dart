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
      required this.items,
      required this.warnings,
      required this.provider});
  final String mealId;
  final String? name;
  final String status;
  final double totalCalories, totalProtein, totalCarbs, totalFat, totalFibre;
  final List<MealReviewItem> items;
  final List<String> warnings;
  final String provider;
  factory MealReview.fromJson(Map<String, dynamic> json) => MealReview(
      mealId: json['mealId'] as String,
      name: json['name'] as String?,
      status: json['status'] as String,
      totalCalories: _number(json['totalCalories']),
      totalProtein: _number(json['totalProteinGrams']),
      totalCarbs: _number(json['totalCarbohydrateGrams']),
      totalFat: _number(json['totalFatGrams']),
      totalFibre: _number(json['totalFibreGrams']),
      items: (json['items'] as List)
          .map((x) =>
              MealReviewItem.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList(),
      warnings: (json['warnings'] as List? ?? const []).cast<String>(),
      provider: json['provider'] as String? ?? 'Unknown');
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
      required this.preparationMethod,
      required this.requiresConfirmation,
      required this.warnings});
  final String id, detectedName, servingUnit, preparationMethod;
  final String? foodId;
  final double? grams;
  final double calories, protein, carbs, fat, fibre;
  final bool requiresConfirmation;
  final List<String> warnings;
  factory MealReviewItem.fromJson(Map<String, dynamic> json) => MealReviewItem(
      id: json['id'] as String,
      detectedName: json['detectedName'] as String,
      foodId: json['foodId'] as String?,
      grams: _nullableNumber(json['estimatedGrams']),
      servingUnit: json['estimatedServingUnit'] as String,
      calories: _number(json['calories']),
      protein: _number(json['proteinGrams']),
      carbs: _number(json['carbohydrateGrams']),
      fat: _number(json['fatGrams']),
      fibre: _number(json['fibreGrams']),
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
