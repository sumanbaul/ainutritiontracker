import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/result/result.dart';
import '../../../core/networking/api_client.dart';
import '../../../shared/presentation/nutrition_ui.dart';
import '../../profile/data/profile_repository.dart';
import '../../auth/data/auth_service.dart';
import '../../profile/domain/profile.dart';
import '../../meal_history/data/meal_history_repository.dart';
import '../../meal_capture/presentation/meal_photo.dart';
import '../data/dashboard_repository.dart';

class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});
  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  late Future<Result<UserProfile?>> _profile;
  late Future<Result<DashboardSummary>> _dashboard;
  late Future<Result<List<MealHistoryItem>>> _history;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _profile = _loadProfile();
    _dashboard = _loadDashboard();
    _history = _loadHistory();
  }

  Future<Result<UserProfile?>> _loadProfile() async {
    final userId = await _userId();
    if (userId == null) return const Success(null);
    final repository = ref.read(profileRepositoryProvider);
    final cached = await repository.getCached(userId);
    if (cached != null) {
      unawaited(repository.get(userId: userId));
      return Success(cached);
    }
    return repository.get(userId: userId);
  }

  Future<Result<DashboardSummary>> _loadDashboard() async {
    final userId = await _userId();
    if (userId == null) return const Failure(AppFailure('No local session.'));
    final repository = ref.read(dashboardRepositoryProvider);
    final cached = await repository.cachedToday(userId, DateTime.now());
    if (cached != null) {
      unawaited(repository.today(userId: userId));
      return Success(cached);
    }
    return repository.today(userId: userId);
  }

  Future<Result<List<MealHistoryItem>>> _loadHistory() async {
    final userId = await _userId();
    if (userId == null) return const Success([]);
    final repository = ref.read(mealHistoryRepositoryProvider);
    final cached = await repository.cachedAll(userId);
    if (cached.isNotEmpty) {
      unawaited(repository.getAllAndCache(userId));
      return Success(cached);
    }
    return repository.getAllAndCache(userId);
  }

  Future<String?> _userId() async =>
      await ref.read(developmentIdentityProvider).currentUserId() ??
      await ref.read(authServiceProvider).userId();

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_profile, _dashboard, _history]);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Result<UserProfile?>>(
        future: _profile,
        builder: (context, profileSnapshot) {
          if (!profileSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = profileSnapshot.data!;
          if (result is! Success<UserProfile?>) {
            return const Center(
                child: Text('NutriLens could not load today’s plan.'));
          }
          final profile = result.value;
          if (profile == null) {
            return const Center(
                child: Text('Complete onboarding to activate your plan.'));
          }
          return FutureBuilder<Result<DashboardSummary>>(
            future: _dashboard,
            builder: (context, dashboardSnapshot) {
              final dashboardResult = dashboardSnapshot.data;
              final summary = dashboardResult is Success<DashboardSummary>
                  ? dashboardResult.value
                  : null;
              return FutureBuilder<Result<List<MealHistoryItem>>>(
                  future: _history,
                  builder: (context, historySnapshot) {
                    final history = historySnapshot.data;
                    return _TodayContent(
                        profile: profile,
                        summary: summary,
                        meals: history is Success<List<MealHistoryItem>>
                            ? history.value.take(6).toList()
                            : const [],
                        onRefresh: _refresh);
                  });
            },
          );
        },
      );
}

class _TodayContent extends StatelessWidget {
  const _TodayContent(
      {required this.profile,
      required this.summary,
      required this.meals,
      required this.onRefresh});
  final UserProfile profile;
  final DashboardSummary? summary;
  final List<MealHistoryItem> meals;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final calories = summary?.calories ?? 0;
    final calorieDelta = profile.target.calories - calories;
    final calorieCaption = calorieDelta >= 0
        ? '${calorieDelta.toStringAsFixed(0)} kcal left'
        : '${(-calorieDelta).toStringAsFixed(0)} kcal over target';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 148),
          children: [
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting, ${profile.name}!',
                          style: const TextStyle(color: AppColors.softInk)),
                      const SizedBox(height: 6),
                      Text('Are you doing good\nwith your plan?',
                          style: Theme.of(context).textTheme.headlineLarge),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                    tooltip: 'Settings',
                    onPressed: () => context.push(RoutePaths.settings),
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: AppColors.ink)),
              ),
            ]),
            const SizedBox(height: 22),
            InkWell(
              onTap: () => context.push(RoutePaths.manualMeal),
              borderRadius: BorderRadius.circular(26),
              child: const IgnorePointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Describe or search your food',
                    suffixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(children: [
              Text('Today at a glance',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              FilledButton.tonalIcon(
                  onPressed: () => context.push(RoutePaths.capture),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Scan new')),
            ]),
            const SizedBox(height: 14),
            NutritionHero(
              value: calories,
              target: profile.target.calories,
              label: 'kcal eaten',
              caption: calorieCaption,
              child: Text(
                '${summary?.mealCount ?? 0} confirmed meals today',
                style: const TextStyle(color: AppColors.cyan),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.timer_outlined, color: AppColors.violet),
                title: const Text('Fasting timer'),
                subtitle:
                    const Text('Start or review your personal tracking target'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.fasting),
              ),
            ),
            if (meals.isNotEmpty) ...[
              const SizedBox(height: 26),
              NutritionSectionTitle('Recent meals',
                  subtitle: 'Tap a meal to see its details',
                  action: TextButton(
                      onPressed: () => context.go(RoutePaths.history),
                      child: const Text('See all'))),
              const SizedBox(height: 12),
              SizedBox(
                height: 172,
                child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: meals.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) =>
                        _MealFeatureCard(meal: meals[index])),
              ),
            ],
            const SizedBox(height: 24),
            const NutritionSectionTitle('Today’s nutrition',
                subtitle: 'Live totals from confirmed meals'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.18,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                NutritionMetricCard(
                    expand: true,
                    label: 'Protein',
                    value: summary?.protein ?? 0,
                    target: profile.target.protein,
                    color: AppColors.pink,
                    icon: Icons.fitness_center),
                NutritionMetricCard(
                    expand: true,
                    label: 'Carbs',
                    value: summary?.carbs ?? 0,
                    target: profile.target.carbohydrates,
                    color: AppColors.warning,
                    icon: Icons.grain),
                NutritionMetricCard(
                    expand: true,
                    label: 'Fat',
                    value: summary?.fat ?? 0,
                    target: profile.target.fat,
                    color: AppColors.cyan,
                    icon: Icons.water_drop_outlined),
                NutritionMetricCard(
                    expand: true,
                    label: 'Fibre',
                    value: summary?.fibre ?? 0,
                    target: profile.target.fibre,
                    color: AppColors.green,
                    icon: Icons.eco_outlined),
              ],
            ),
            const SizedBox(height: 26),
            const NutritionSectionTitle('Quick actions'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.camera_alt_outlined,
                  label: 'Scan meal',
                  color: AppColors.indigo,
                  onTap: () => context.push(RoutePaths.capture),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.edit_note_outlined,
                  label: 'Log manually',
                  color: AppColors.green,
                  onTap: () => context.push(RoutePaths.manualMeal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.water_drop_outlined,
                  label: 'Habits',
                  color: AppColors.cyan,
                  onTap: () => context.push(RoutePaths.habits),
                ),
              ),
            ]),
            if ((summary?.mealCount ?? 0) == 0) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    const Icon(Icons.auto_awesome, color: AppColors.violet),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                          'Your day is ready. Scan or manually add your first meal.'),
                    ),
                    IconButton(
                        onPressed: () => context.push(RoutePaths.capture),
                        icon: const Icon(Icons.arrow_forward)),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealFeatureCard extends StatelessWidget {
  const _MealFeatureCard({required this.meal});
  final MealHistoryItem meal;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push(RoutePaths.review(meal.id)),
          child: SizedBox(
            width: 154,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(fit: StackFit.expand, children: [
                MealPhoto(mealId: meal.id, hasImage: meal.hasImage, hero: true),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xDD000000)]))),
                Positioned(
                    left: 11,
                    right: 11,
                    top: 11,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.22),
                            borderRadius: BorderRadius.circular(16)),
                        child: Text('${meal.calories.toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    )),
                Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(meal.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.white)),
                          Text(
                              '${meal.type} • ${meal.protein.toStringAsFixed(0)}g protein',
                              style: const TextStyle(color: Colors.white70)),
                        ])),
              ]),
            ),
          ),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(.22)),
          ),
          child: Column(children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ]),
        ),
      );
}
