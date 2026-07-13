abstract final class RoutePaths {
  static const splash = '/splash',
      setup = '/development-setup',
      home = '/home',
      dashboard = '/dashboard',
      profile = '/profile',
      settings = '/settings',
      onboarding = '/onboarding',
      capture = '/meal/capture',
      manualMeal = '/meal/manual',
      history = '/history',
      weight = '/weight';
  static String review(String mealId) => '/meal/review/$mealId';
}
