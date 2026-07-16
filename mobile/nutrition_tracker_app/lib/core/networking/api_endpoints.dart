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
  static const manualMeal = '/api/meals/manual';
  static String mealReview(String id) => '/api/meals/$id/review';
  static String mealImage(String id) => '/api/meals/$id/image';
  static String mealItem(String mealId, String itemId) =>
      '/api/meals/$mealId/items/$itemId';
  static String mealItemResolution(String mealId, String itemId) =>
      '/api/meals/$mealId/items/$itemId/resolve';
  static String mealItemEstimateConfirmation(String mealId, String itemId) =>
      '/api/meals/$mealId/items/$itemId/resolve/estimate/confirm';
  static String mealItems(String mealId) => '/api/meals/$mealId/items';
  static String mealConfirm(String id) => '/api/meals/$id/confirm';
  static String mealCorrections(String id) => '/api/meals/$id/corrections';
  static const mealHistory = '/api/meals';
  static const mealActivity = '/api/meals/activity';
  static const dashboardToday = '/api/dashboard/today';
  static const mealVisionCapabilities = '/api/meal-vision/capabilities';
  static const habitSummary = '/api/habits/summary';
  static const hydration = '/api/habits/hydration';
  static const fasting = '/api/habits/fasting';
  static const activeFast = '/api/fasting/active';
  static const fastingHistory = '/api/fasting/history';
  static const startFast = '/api/fasting/start';
  static String endFast(String id) => '/api/fasting/$id/end';
  static String cancelFast(String id) => '/api/fasting/$id/cancel';
  static const reminders = '/api/habits/reminders';
  static String reminder(String id) => '/api/habits/reminders/$id';
}
