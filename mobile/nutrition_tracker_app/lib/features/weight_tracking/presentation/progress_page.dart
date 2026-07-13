import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/result/result.dart';
import '../../../shared/presentation/nutrition_ui.dart';
import '../../habits/data/habit_repository.dart';
import '../data/weight_repository.dart';

class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});
  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  String _period = 'weekly';
  late Future<Result<List<WeightEntry>>> _weights;
  late Future<Result<HabitSummary>> _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _weights = ref.read(weightRepositoryProvider).getAll();
    _summary = ref.read(habitRepositoryProvider).summary(_period);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_weights, _summary]);
  }

  Future<void> _addWeight() async {
    final controller = TextEditingController();
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const NutritionSectionTitle('Log weight',
              subtitle: 'Add today’s body metric.'),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Weight', suffixText: 'kg'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save weight'),
          ),
        ]),
      ),
    );
    controller.dispose();
    if (value == null || value < 25 || value > 400) return;
    await ref.read(weightRepositoryProvider).add(value, null);
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<Result<HabitSummary>>(
            future: _summary,
            builder: (context, summarySnapshot) =>
                FutureBuilder<Result<List<WeightEntry>>>(
              future: _weights,
              builder: (context, weightSnapshot) {
                if (!summarySnapshot.hasData || !weightSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final summaryResult = summarySnapshot.data!;
                final weightResult = weightSnapshot.data!;
                if (summaryResult is! Success<HabitSummary> ||
                    weightResult is! Success<List<WeightEntry>>) {
                  return ListView(children: const [
                    SizedBox(height: 250),
                    Center(child: Text('Progress data could not be loaded.')),
                  ]);
                }
                return _content(summaryResult.value, weightResult.value);
              },
            ),
          ),
        ),
      );

  Widget _content(HabitSummary summary, List<WeightEntry> weights) {
    final change = summary.weightChangeKg;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your progress',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Text('Trends that turn daily choices into momentum.',
                  style: TextStyle(color: AppColors.secondaryText)),
            ]),
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'weekly', label: Text('7D')),
              ButtonSegment(value: 'monthly', label: Text('30D')),
            ],
            selected: {_period},
            showSelectedIcon: false,
            onSelectionChanged: (value) {
              setState(() {
                _period = value.first;
                _load();
              });
            },
          ),
        ]),
        const SizedBox(height: 12),
        _ProgressStat(
          icon: Icons.timer_outlined,
          color: AppColors.violet,
          value:
              '${summary.fastingMinutes ~/ 60}h ${summary.fastingMinutes % 60}m',
          label: 'completed fasting this period',
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              gradient: AppGradients.hero,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(.08))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.monitor_weight_outlined, color: AppColors.cyan),
              const SizedBox(width: 10),
              const Text('Weight trend',
                  style: TextStyle(color: AppColors.secondaryText)),
              const Spacer(),
              IconButton.filledTonal(
                  tooltip: 'Log weight',
                  onPressed: _addWeight,
                  icon: const Icon(Icons.add)),
            ]),
            Text(
              summary.currentWeightKg == null
                  ? 'No data'
                  : '${summary.currentWeightKg!.toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.primaryText),
            ),
            Text(
              change == null
                  ? 'Add more entries to see your trend'
                  : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg this period',
              style: TextStyle(
                  color: change != null && change < 0
                      ? AppColors.green
                      : AppColors.secondaryText),
            ),
            const SizedBox(height: 18),
            SizedBox(height: 110, child: _WeightChart(entries: weights)),
          ]),
        ),
        const SizedBox(height: 22),
        const NutritionSectionTitle('Nutrition consistency'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _ProgressStat(
              icon: Icons.local_fire_department_outlined,
              color: AppColors.warning,
              value: summary.averageCalories.toStringAsFixed(0),
              label: 'avg kcal/day',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ProgressStat(
              icon: Icons.track_changes,
              color: AppColors.green,
              value: summary.calorieAdherencePercent == null
                  ? '—'
                  : '${summary.calorieAdherencePercent!.toStringAsFixed(0)}%',
              label: 'target adherence',
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _ProgressStat(
              icon: Icons.restaurant_outlined,
              color: AppColors.violet,
              value: '${summary.confirmedMeals}',
              label: 'confirmed meals',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ProgressStat(
              icon: Icons.water_drop_outlined,
              color: AppColors.cyan,
              value:
                  '${(summary.hydrationMillilitres / 1000).toStringAsFixed(1)}L',
              label: 'water logged',
            ),
          ),
        ]),
        const SizedBox(height: 22),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: Color(0x2255F991),
              child: Icon(Icons.bolt_outlined, color: AppColors.green),
            ),
            title: const Text('Habits & routines'),
            subtitle: const Text('Hydration, fasting, and local reminders'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => context.push(RoutePaths.habits),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Trends and adherence are informational and are not medical advice.',
          style: TextStyle(color: AppColors.mutedText, fontSize: 12),
        ),
      ],
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});
  final IconData icon;
  final Color color;
  final String value, label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.secondaryText)),
        ]),
      );
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.entries});
  final List<WeightEntry> entries;
  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return const Center(
          child: Text('Your chart appears after two weight entries.',
              style: TextStyle(color: AppColors.mutedText)));
    }
    final points = entries.reversed.take(30).map((e) => e.weightKg).toList();
    return CustomPaint(painter: _LineChartPainter(points));
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 1);
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = index / (values.length - 1) * size.width;
      final y =
          size.height - ((values[index] - minValue) / range * size.height);
      index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
