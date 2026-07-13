import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/development_setup/presentation/development_setup_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/meal_capture/presentation/capture_preview_page.dart';
import '../../features/meal_capture/presentation/meal_review_page.dart';
import '../../features/meal_capture/presentation/manual_meal_page.dart';
import '../../features/habits/presentation/habits_page.dart';
import '../../shared/presentation/app_shell.dart';
import '../../shared/presentation/placeholder_page.dart';
import '../../features/auth/presentation/sign_in_page.dart';
import '../../features/recipes/presentation/recipe_picker_page.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((_) => GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(path: '/', redirect: (_, __) => RoutePaths.splash),
      GoRoute(path: RoutePaths.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: RoutePaths.signIn, builder: (_, __) => const SignInPage()),
      GoRoute(
          path: RoutePaths.setup,
          builder: (_, __) => const DevelopmentSetupPage()),
      GoRoute(path: RoutePaths.home, builder: (_, __) => const AppShell()),
      GoRoute(
          path: RoutePaths.settings, builder: (_, __) => const SettingsPage()),
      GoRoute(
          path: RoutePaths.dashboard,
          builder: (_, __) => const PlaceholderPage(
              title: 'Today', message: 'Dashboard details arrive in Phase 9.')),
      GoRoute(
          path: RoutePaths.profile,
          builder: (_, __) => const PlaceholderPage(
              title: 'Profile',
              message: 'Profile management arrives in Phase 9.')),
      GoRoute(
          path: RoutePaths.onboarding,
          builder: (_, __) => const OnboardingPage()),
      GoRoute(
          path: RoutePaths.capture,
          builder: (_, __) => const CapturePreviewPage()),
      GoRoute(
          path: RoutePaths.manualMeal,
          builder: (_, __) => const ManualMealPage()),
      GoRoute(
          path: RoutePaths.recipes,
          builder: (_, __) => const RecipePickerPage()),
      GoRoute(path: RoutePaths.habits, builder: (_, __) => const HabitsPage()),
      GoRoute(
          path: RoutePaths.history,
          builder: (_, __) => const PlaceholderPage(
              title: 'History', message: 'Meal history arrives in Phase 10.')),
      GoRoute(
          path: RoutePaths.weight,
          builder: (_, __) => const PlaceholderPage(
              title: 'Progress',
              message: 'Weight tracking arrives in Phase 9.')),
      GoRoute(
          path: '/meal/review/:mealId',
          builder: (_, state) =>
              MealReviewPage(mealId: state.pathParameters['mealId']!))
    ],
    errorBuilder: (_, __) => const PlaceholderPage(
        title: 'Page not found', message: 'This route is unavailable.')));
