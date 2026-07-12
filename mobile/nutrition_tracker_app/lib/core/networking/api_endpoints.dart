abstract final class ApiEndpoints {
  static const health = '/health';
  static const readiness = '/health/ready';
  static const profile = '/api/profile';
  static const profileRecalculateTargets = '/api/profile/recalculate-targets';
  static const weight = '/api/weight';
  static const foodsSearch = '/api/foods/search';
  static String food(String id) => '/api/foods/$id';
  static const foodCalculateGrams = '/api/foods/calculate/grams';
  static const foodCalculateServing = '/api/foods/calculate/serving';
  static const customFoods = '/api/foods/custom';
  static String customFood(String id) => '/api/foods/custom/$id';
  static const mealAnalysis = '/api/meals/analyse';
  static String mealReview(String id) => '/api/meals/$id/review';
  static String mealItem(String mealId, String itemId) =>
      '/api/meals/$mealId/items/$itemId';
  static String mealItems(String mealId) => '/api/meals/$mealId/items';
  static String mealConfirm(String id) => '/api/meals/$id/confirm';
  static String mealCorrections(String id) => '/api/meals/$id/corrections';
  static const mealHistory = '/api/meals';
  static const dashboardToday = '/api/dashboard/today';
}
