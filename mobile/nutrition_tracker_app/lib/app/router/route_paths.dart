abstract final class RoutePaths {
  static const splash = '/splash',
      signIn = '/sign-in',
      setup = '/development-setup',
      home = '/home',
      dashboard = '/dashboard',
      profile = '/profile',
      settings = '/settings',
      onboarding = '/onboarding',
      capture = '/meal/capture',
      manualMeal = '/meal/manual',
      recipes = '/recipes',
      discoverMeals = '/discover-meals',
      habits = '/habits',
      fasting = '/fasting',
      history = '/history',
      weight = '/weight';
  static String review(String mealId) => '/meal/review/$mealId';
}
