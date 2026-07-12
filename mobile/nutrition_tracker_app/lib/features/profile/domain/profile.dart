class NutritionTarget {
  const NutritionTarget(
      {required this.calories,
      required this.protein,
      required this.carbohydrates,
      required this.fat,
      required this.fibre,
      required this.bmr,
      required this.tdee});
  final double calories, protein, carbohydrates, fat, fibre, bmr, tdee;
  factory NutritionTarget.fromJson(Map<String, dynamic> j) => NutritionTarget(
      calories: _n(j['targetCalories']),
      protein: _n(j['proteinGrams']),
      carbohydrates: _n(j['carbohydrateGrams']),
      fat: _n(j['fatGrams']),
      fibre: _n(j['fibreGrams']),
      bmr: _n(j['basalMetabolicRate']),
      tdee: _n(j['totalDailyEnergyExpenditure']));
}

class UserProfile {
  const UserProfile(
      {required this.name,
      required this.dateOfBirth,
      required this.biologicalSex,
      required this.currentWeight,
      required this.targetWeight,
      required this.height,
      required this.age,
      required this.activity,
      required this.goal,
      required this.diet,
      required this.measurement,
      required this.timezone,
      required this.target});
  final String name, biologicalSex, activity, goal, diet, measurement, timezone;
  final DateTime dateOfBirth;
  final double currentWeight, targetWeight, height;
  final int age;
  final NutritionTarget target;
  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
      name: j['name'] as String,
      dateOfBirth: DateTime.parse(j['dateOfBirth'] as String),
      biologicalSex: j['biologicalSex'] as String,
      currentWeight: _n(j['currentWeightKg']),
      targetWeight: _n(j['targetWeightKg']),
      height: _n(j['heightCm']),
      age: j['age'] as int,
      activity: j['activityLevel'] as String,
      goal: j['goalType'] as String,
      diet: j['dietPreference'] as String,
      measurement: j['preferredMeasurementSystem'] as String,
      timezone: j['timezone'] as String,
      target: NutritionTarget.fromJson(
          j['currentNutritionTarget'] as Map<String, dynamic>));
}

double _n(Object? value) => (value as num?)?.toDouble() ?? 0;
