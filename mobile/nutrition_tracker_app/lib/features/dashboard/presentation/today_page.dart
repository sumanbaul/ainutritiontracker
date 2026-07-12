import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/result/result.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../data/dashboard_repository.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<
          Result<UserProfile?>>(
      future: ref.watch(profileRepositoryProvider).get(),
      builder: (context, profileSnapshot) {
        if (!profileSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final profileResult = profileSnapshot.data!;
        if (profileResult is! Success<UserProfile?>) {
          return const Center(
              child: Text(
                  'Signal lost\nThe NutriLens API could not be reached.',
                  textAlign: TextAlign.center));
        }
        final profile = profileResult.value;
        if (profile == null) {
          return const Center(
              child: Text(
                  'Your nutrition feed is empty.\nComplete onboarding to activate your protocol.',
                  textAlign: TextAlign.center));
        }
        return FutureBuilder<Result<DashboardSummary>>(
            future: ref.watch(dashboardRepositoryProvider).today(),
            builder: (context, dashboardSnapshot) {
              final dashboardResult = dashboardSnapshot.data;
              final summary = dashboardResult is Success<DashboardSummary>
                  ? dashboardResult.value
                  : null;
              final consumed = summary?.calories ?? 0;
              final remaining = (profile.target.calories - consumed)
                  .clamp(0, double.infinity);
              final progress = profile.target.calories <= 0
                  ? 0.0
                  : (consumed / profile.target.calories).clamp(0, 1).toDouble();
              return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(profileRepositoryProvider);
                    ref.invalidate(dashboardRepositoryProvider);
                  },
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    Text('Good morning, ${profile.name}',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DAILY PROTOCOL'),
                                  const SizedBox(height: 8),
                                  Text(
                                      '${consumed.toStringAsFixed(0)} / ${profile.target.calories.toStringAsFixed(0)} kcal',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall),
                                  Text(
                                      '${remaining.toStringAsFixed(0)} kcal remaining'),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                      value: progress,
                                      semanticsLabel:
                                          '${(progress * 100).round()} percent of calorie target')
                                ]))),
                    const SizedBox(height: 16),
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      _Macro('Protein', summary?.protein ?? 0,
                          profile.target.protein),
                      _Macro('Carbs', summary?.carbs ?? 0,
                          profile.target.carbohydrates),
                      _Macro('Fat', summary?.fat ?? 0, profile.target.fat),
                      _Macro('Fibre', summary?.fibre ?? 0, profile.target.fibre)
                    ]),
                    const SizedBox(height: 28),
                    Text(
                        (summary?.mealCount ?? 0) == 0
                            ? 'No fuel data yet\nScan your first meal to activate today’s nutrition protocol.'
                            : '${summary!.mealCount} confirmed meal${summary.mealCount == 1 ? '' : 's'} logged today.',
                        textAlign: TextAlign.center)
                  ]));
            });
      });
}

class _Macro extends StatelessWidget {
  const _Macro(this.label, this.consumed, this.target);
  final String label;
  final double consumed, target;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 150,
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label),
                    Text(
                        '${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: target <= 0
                            ? 0
                            : (consumed / target).clamp(0, 1).toDouble())
                  ]))));
}
