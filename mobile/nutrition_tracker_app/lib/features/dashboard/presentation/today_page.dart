import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/result/result.dart';
import '../../../shared/presentation/glass_ui.dart';
import '../../auth/data/auth_service.dart';
import '../../habits/data/habit_repository.dart';
import '../../meal_capture/presentation/meal_photo.dart';
import '../../meal_history/data/meal_history_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
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
  late Future<Result<HabitSummary>> _habits;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _profile = _loadProfile();
    _dashboard = _loadDashboard();
    _history = _loadHistory();
    _habits = ref.read(habitRepositoryProvider).summary('daily');
  }

  Future<String?> _userId() async =>
      await ref.read(developmentIdentityProvider).currentUserId() ??
      await ref.read(authServiceProvider).userId();

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

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_profile, _dashboard, _history, _habits]);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Result<UserProfile?>>(
        future: _profile,
        builder: (context, profileSnapshot) {
          if (!profileSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = profileSnapshot.data!;
          if (result is! Success<UserProfile?> || result.value == null) {
            return const Center(
                child: Text('Complete onboarding to activate your plan.'));
          }
          return FutureBuilder<Result<DashboardSummary>>(
            future: _dashboard,
            builder: (context, dashboardSnapshot) =>
                FutureBuilder<Result<List<MealHistoryItem>>>(
              future: _history,
              builder: (context, historySnapshot) =>
                  FutureBuilder<Result<HabitSummary>>(
                future: _habits,
                builder: (context, habitsSnapshot) => _TodayContent(
                  profile: result.value!,
                  summary: dashboardSnapshot.data is Success<DashboardSummary>
                      ? (dashboardSnapshot.data! as Success<DashboardSummary>)
                          .value
                      : null,
                  meals: historySnapshot.data is Success<List<MealHistoryItem>>
                      ? (historySnapshot.data!
                              as Success<List<MealHistoryItem>>)
                          .value
                          .take(6)
                          .toList()
                      : const [],
                  habits: habitsSnapshot.data is Success<HabitSummary>
                      ? (habitsSnapshot.data! as Success<HabitSummary>).value
                      : null,
                  hydrationAvailable: habitsSnapshot.connectionState !=
                          ConnectionState.waiting &&
                      habitsSnapshot.data is Success<HabitSummary>,
                  onRefresh: _refresh,
                ),
              ),
            ),
          );
        },
      );
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({
    required this.profile,
    required this.summary,
    required this.meals,
    required this.habits,
    required this.hydrationAvailable,
    required this.onRefresh,
  });
  final UserProfile profile;
  final DashboardSummary? summary;
  final List<MealHistoryItem> meals;
  final HabitSummary? habits;
  final bool hydrationAvailable;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final calories = summary?.calories ?? 0;
    final calorieDelta = profile.target.calories - calories;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: palette.accent,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 126),
          children: [
            Row(children: [
              const NutriLensBrand(),
              const Spacer(),
              _RoundIconButton(
                  label: 'Notifications',
                  icon: Icons.notifications_none_rounded,
                  onTap: () => context.push(RoutePaths.settings)),
            ]),
            const SizedBox(height: 22),
            Text('$greeting, ${profile.name}!',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
                children: [
                  const TextSpan(text: 'Healthy Today,\n'),
                  TextSpan(
                      text: 'Stronger ',
                      style: TextStyle(
                          color: palette.accent, fontStyle: FontStyle.italic)),
                  const TextSpan(text: 'Tomorrow.'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _FoodSearch(
                onSearch: () => context.push(RoutePaths.manualMeal),
                onScan: () => context.push(RoutePaths.capture)),
            const SizedBox(height: 16),
            GlassSurface(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
              accent: palette.accent,
              child: Column(children: [
                Row(children: [
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 156,
                      child: _ProgressRings(
                        calories: _fraction(calories, profile.target.calories),
                        protein: _fraction(
                            summary?.protein ?? 0, profile.target.protein),
                        hydration:
                            _fraction(habits?.hydrationMillilitres ?? 0, 2500),
                        accent: palette.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 6,
                    child: Column(children: [
                      _RingLabel(
                          color: palette.accent,
                          label: 'Calories',
                          value:
                              '${calories.toStringAsFixed(0)} / ${profile.target.calories.toStringAsFixed(0)} kcal'),
                      const SizedBox(height: 12),
                      _RingLabel(
                          color: const Color(0xff55C95B),
                          label: 'Protein',
                          value:
                              '${(summary?.protein ?? 0).toStringAsFixed(0)} / ${profile.target.protein.toStringAsFixed(0)} g'),
                      const SizedBox(height: 12),
                      _RingLabel(
                          color: const Color(0xff26BDEB),
                          label: 'Hydration',
                          value: hydrationAvailable
                              ? '${((habits?.hydrationMillilitres ?? 0) / 1000).toStringAsFixed(1)} / 2.5 L'
                              : 'Unavailable'),
                    ]),
                  ),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(
                          Theme.of(context).brightness == Brightness.dark
                              ? .22
                              : .04),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              '${calorieDelta.abs().toStringAsFixed(0)} kcal ${calorieDelta >= 0 ? 'left' : 'over'}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                              '${profile.target.calories.toStringAsFixed(0)} daily target',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppSemanticColors.of(context).muted)),
                        ])),
                    Text('${summary?.mealCount ?? 0}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(width: 5),
                    Text('Meals\ntoday',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            color: AppSemanticColors.of(context).muted)),
                  ]),
                )
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              _QuickAction(
                  icon: Icons.camera_alt_outlined,
                  title: 'Scan Meal',
                  subtitle: 'AI Analysis',
                  onTap: () => context.push(RoutePaths.capture)),
              _QuickAction(
                  icon: Icons.edit_note_outlined,
                  title: 'Manual Log',
                  subtitle: 'Add Food',
                  onTap: () => context.push(RoutePaths.manualMeal)),
              _QuickAction(
                  icon: Icons.water_drop_outlined,
                  title: 'Hydration',
                  subtitle: 'Track Water',
                  onTap: () => context.push(RoutePaths.habits)),
              _QuickAction(
                  icon: Icons.timer_outlined,
                  title: 'Fasting',
                  subtitle: 'Start Timer',
                  onTap: () => context.push(RoutePaths.fasting)),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Text('Recent Meals',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(
                  onPressed: () => context.go(RoutePaths.history),
                  child: const Text('See All')),
            ]),
            const SizedBox(height: 8),
            if (meals.isEmpty)
              _EmptyMeals(onTap: () => context.push(RoutePaths.capture))
            else
              SizedBox(
                height: 122,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: meals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) =>
                      _MealCard(meal: meals[index]),
                ),
              ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.push(RoutePaths.discoverMeals),
              child: GlassSurface(
                accent: palette.accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Icon(Icons.restaurant_menu_rounded, color: palette.accent),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('What should I cook?',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        Text('A 7-day cuisine plan tailored to you.',
                            style: TextStyle(fontSize: 12)),
                      ])),
                  const Icon(Icons.arrow_forward_rounded),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.push(RoutePaths.weight),
              child: GlassSurface(
                accent: palette.accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  Icon(Icons.auto_awesome_rounded, color: palette.accent),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Small steps, big results.',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        Text('You’re doing great!',
                            style: TextStyle(fontSize: 12)),
                      ])),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _fraction(double value, double target) =>
      target <= 0 ? 0 : (value / target).clamp(0, 1);
}

class _FoodSearch extends StatelessWidget {
  const _FoodSearch({required this.onSearch, required this.onScan});
  final VoidCallback onSearch, onScan;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: InkWell(
                onTap: onSearch,
                borderRadius: BorderRadius.circular(18),
                child: const IgnorePointer(
                    child: TextField(
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            hintText: 'Describe or search your food...'))))),
        const SizedBox(width: 9),
        Semantics(
            label: 'Scan meal',
            button: true,
            child: FilledButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Scan'))),
      ]);
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
      label: label,
      button: true,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: GlassSurface(
              radius: 22,
              padding: const EdgeInsets.all(10),
              child:
                  Icon(icon, size: 21, color: AppPalette.of(context).accent))));
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Semantics(
              button: true,
              label: title,
              child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: GlassSurface(
                      radius: 16,
                      padding: const EdgeInsets.symmetric(
                          vertical: 11, horizontal: 3),
                      child: Column(children: [
                        Icon(icon,
                            color: AppPalette.of(context).accent, size: 21),
                        const SizedBox(height: 6),
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 10)),
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 8,
                                color: AppSemanticColors.of(context).muted))
                      ]))))));
}

class _RingLabel extends StatelessWidget {
  const _RingLabel(
      {required this.color, required this.label, required this.value});
  final Color color;
  final String label, value;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.radio_button_checked, color: color, size: 12),
        const SizedBox(width: 7),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 11)),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))
        ]))
      ]);
}

class _ProgressRings extends StatelessWidget {
  const _ProgressRings(
      {required this.calories,
      required this.protein,
      required this.hydration,
      required this.accent});
  final double calories, protein, hydration;
  final Color accent;
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _ProgressRingsPainter(calories, protein, hydration, accent),
      child: const SizedBox.expand());
}

class _ProgressRingsPainter extends CustomPainter {
  const _ProgressRingsPainter(
      this.calories, this.protein, this.hydration, this.accent);
  final double calories, protein, hydration;
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = math.min(size.width, size.height) / 2 - 4;
    final values = [
      (maxRadius, calories, accent),
      (maxRadius - 18, protein, const Color(0xff55C95B)),
      (maxRadius - 36, hydration, const Color(0xff26BDEB))
    ];
    for (final item in values) {
      final rect = Rect.fromCircle(center: center, radius: item.$1);
      final base = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = item.$3.withOpacity(.16);
      final active = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = item.$3;
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, base);
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * item.$2, false, active);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingsPainter old) =>
      old.calories != calories ||
      old.protein != protein ||
      old.hydration != hydration ||
      old.accent != accent;
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});
  final MealHistoryItem meal;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 126,
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: () => context.push(RoutePaths.review(meal.id)),
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(fit: StackFit.expand, children: [
                    MealPhoto(
                        mealId: meal.id, hasImage: meal.hasImage, hero: true),
                    const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                          Colors.transparent,
                          Color(0xD9000000)
                        ]))),
                    Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.54),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                '${meal.calories.toStringAsFixed(0)} kcal',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700)))),
                    Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meal.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800)),
                              Text(
                                  '${meal.type} · ${meal.protein.toStringAsFixed(0)}g protein',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 9))
                            ]))
                  ])))));
}

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: GlassSurface(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Icon(Icons.camera_alt_outlined,
                color: AppPalette.of(context).accent),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('Your day is ready. Scan your first meal.')),
            const Icon(Icons.arrow_forward_rounded)
          ])));
}
