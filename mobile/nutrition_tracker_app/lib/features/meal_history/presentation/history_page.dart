import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/result/result.dart';
import '../../meal_capture/presentation/meal_photo.dart';
import '../data/meal_history_repository.dart';

enum ActivityMetric { meals, adherence }

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  late Future<Result<MealActivity>> _activity;
  late Future<Result<List<MealHistoryItem>>> _meals;
  MealActivityDay? _selectedDay;
  ActivityMetric _metric = ActivityMetric.meals;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());
  DateTime get _from => _today.subtract(const Duration(days: 364));

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repository = ref.read(mealHistoryRepositoryProvider);
    _activity = repository.getActivity(_from, _today);
    _meals = _selectedDay == null
        ? repository.getAll()
        : repository.getRange(_selectedDay!.startUtc, _selectedDay!.endUtc);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_activity, _meals]);
  }

  void _selectDay(MealActivityDay day) {
    final repository = ref.read(mealHistoryRepositoryProvider);
    setState(() {
      _selectedDay = day;
      _meals = repository.getRange(day.startUtc, day.endUtc);
    });
  }

  void _clearDay() {
    setState(() {
      _selectedDay = null;
      _meals = ref.read(mealHistoryRepositoryProvider).getAll();
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<Result<MealActivity>>(
            future: _activity,
            builder: (context, activitySnapshot) =>
                FutureBuilder<Result<List<MealHistoryItem>>>(
              future: _meals,
              builder: (context, mealSnapshot) {
                final activityResult = activitySnapshot.data;
                final mealResult = mealSnapshot.data;
                final activity = activityResult is Success<MealActivity>
                    ? activityResult.value
                    : null;
                final meals = mealResult is Success<List<MealHistoryItem>>
                    ? mealResult.value
                    : null;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 124),
                  children: [
                    Text('Your food story',
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 5),
                    Text('Every confirmed meal, in one place.',
                        style: TextStyle(
                            color: AppSemanticColors.of(context).muted)),
                    const SizedBox(height: 22),
                    if (activitySnapshot.connectionState ==
                        ConnectionState.waiting)
                      const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()))
                    else if (activity == null)
                      _messageCard('Daily activity could not be loaded.')
                    else ...[
                      Row(children: [
                        Expanded(
                          child: Text('12-month activity',
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        SegmentedButton<ActivityMetric>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                                value: ActivityMetric.meals,
                                label: Text('Meals')),
                            ButtonSegment(
                                value: ActivityMetric.adherence,
                                label: Text('Target')),
                          ],
                          selected: {_metric},
                          onSelectionChanged: (selection) =>
                              setState(() => _metric = selection.first),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        _metric == ActivityMetric.meals
                            ? 'Darker days contain more confirmed meals.'
                            : 'Darker days are closer to the calorie target.',
                        style: TextStyle(
                            color: AppSemanticColors.of(context).muted),
                      ),
                      const SizedBox(height: 12),
                      ActivityHeatmap(
                        activity: activity,
                        metric: _metric,
                        selectedDate: _selectedDay?.date,
                        onSelected: _selectDay,
                      ),
                      const SizedBox(height: 12),
                      Text('Timezone: ${activity.timezone}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                    if (_selectedDay != null) ...[
                      const SizedBox(height: 18),
                      _SelectedDaySummary(
                          day: _selectedDay!, onClear: _clearDay),
                    ],
                    const SizedBox(height: 24),
                    Text(
                        _selectedDay == null
                            ? 'Recent meals'
                            : 'Meals that day',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (mealSnapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()))
                    else if (meals == null)
                      _messageCard('Meal history sync failed. Pull to retry.')
                    else if (meals.isEmpty)
                      _messageCard(_selectedDay == null
                          ? 'No confirmed meals yet.'
                          : 'No confirmed meals on this day.')
                    else
                      ..._mealWidgets(meals),
                  ],
                );
              },
            ),
          ),
        ),
      );

  List<Widget> _mealWidgets(List<MealHistoryItem> meals) {
    final widgets = <Widget>[];
    DateTime? previous;
    for (var index = 0; index < meals.length; index++) {
      final meal = meals[index];
      final date = DateUtils.dateOnly(meal.consumedAt);
      if (previous == null || !DateUtils.isSameDay(previous, date)) {
        widgets.add(Padding(
          padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 8, bottom: 9),
          child: Text(_friendlyDate(date),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ));
        previous = date;
      }
      widgets.add(_AnimatedMealCard(meal: meal, order: index));
    }
    return widgets;
  }

  Widget _messageCard(String message) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: Text(message, textAlign: TextAlign.center)),
        ),
      );
}

class ActivityHeatmap extends StatefulWidget {
  const ActivityHeatmap({
    super.key,
    required this.activity,
    required this.metric,
    required this.selectedDate,
    required this.onSelected,
  });

  final MealActivity activity;
  final ActivityMetric metric;
  final DateTime? selectedDate;
  final ValueChanged<MealActivityDay> onSelected;

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (_scrollController.hasClients &&
        _scrollController.position.hasContentDimensions) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final byDate = {
      for (final day in widget.activity.days) _key(day.date): day
    };
    final first = widget.activity.fromDate.subtract(
        Duration(days: widget.activity.fromDate.weekday - DateTime.monday));
    final trailing = DateTime.sunday - widget.activity.toDate.weekday;
    final last = widget.activity.toDate.add(Duration(days: trailing));
    final totalDays = last.difference(first).inDays + 1;
    final weeks = totalDays ~/ 7;
    const cellExtent = 16.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppSemanticColors.of(context).glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(top: 22),
              child: SizedBox(
                width: 22,
                child: Column(children: [
                  _WeekdayLabel('M'),
                  _WeekdayLabel(''),
                  _WeekdayLabel('W'),
                  _WeekdayLabel(''),
                  _WeekdayLabel('F'),
                  _WeekdayLabel(''),
                  _WeekdayLabel(''),
                ]),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(weeks, (week) {
                          final weekStart = first.add(Duration(days: week * 7));
                          final label = weekStart.day <= 7
                              ? _months[weekStart.month - 1]
                              : '';
                          return SizedBox(
                              width: cellExtent,
                              height: 22,
                              child: Text(label,
                                  overflow: TextOverflow.visible,
                                  style:
                                      Theme.of(context).textTheme.labelSmall));
                        }),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(weeks, (week) {
                          return Column(
                            children: List.generate(7, (weekday) {
                              final date =
                                  first.add(Duration(days: week * 7 + weekday));
                              final day = byDate[_key(date)];
                              return _dayCell(context, day, cellExtent);
                            }),
                          );
                        }),
                      ),
                    ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('Less', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: 5),
            ...List.generate(
                5,
                (level) => Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _levelColor(context, level / 4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
            const SizedBox(width: 5),
            Text('More', style: Theme.of(context).textTheme.labelSmall),
          ]),
        ]),
      ),
    );
  }

  Widget _dayCell(BuildContext context, MealActivityDay? day, double extent) {
    final selected =
        day != null && DateUtils.isSameDay(day.date, widget.selectedDate);
    final level = day == null ? 0.0 : _level(day);
    final label = day == null
        ? 'Outside activity range'
        : '${_friendlyDate(day.date)}: ${day.mealCount} meals, ${day.calories.toStringAsFixed(0)} calories${day.adherencePercent == null ? '' : ', ${day.adherencePercent!.toStringAsFixed(0)} percent of target'}';
    return Semantics(
      button: day != null,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: day == null ? null : () => widget.onSelected(day),
          child: AnimatedContainer(
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 180),
            width: extent - 3,
            height: extent - 3,
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: _levelColor(context, level),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: selected
                    ? AppSemanticColors.of(context).foreground
                    : AppSemanticColors.of(context).glassBorder,
                width: selected ? 1.6 : .6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _level(MealActivityDay day) {
    if (widget.metric == ActivityMetric.meals) {
      return (day.mealCount.clamp(0, 4) / 4).toDouble();
    }
    final adherence = day.adherencePercent;
    if (adherence == null) return 0;
    return (1 - ((adherence - 100).abs() / 100)).clamp(0, 1).toDouble();
  }

  Color _levelColor(BuildContext context, double level) {
    if (level <= 0) {
      return Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(.45);
    }
    final base = widget.metric == ActivityMetric.meals
        ? AppColors.indigo
        : AppColors.green;
    return base.withOpacity(.20 + .78 * level);
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 16,
        child: Text(text, style: Theme.of(context).textTheme.labelSmall),
      );
}

class _SelectedDaySummary extends StatelessWidget {
  const _SelectedDaySummary({required this.day, required this.onClear});
  final MealActivityDay day;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_friendlyDate(day.date),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                        '${day.mealCount} confirmed meals • ${day.calories.toStringAsFixed(0)} kcal${day.adherencePercent == null ? '' : ' • ${day.adherencePercent!.toStringAsFixed(0)}% of target'}'),
                  ]),
            ),
            IconButton(
              tooltip: 'Show all meal history',
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
          ]),
        ),
      );
}

class _AnimatedMealCard extends StatelessWidget {
  const _AnimatedMealCard({required this.meal, required this.order});
  final MealHistoryItem meal;
  final int order;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: reduce
          ? Duration.zero
          : Duration(milliseconds: 380 + (order.clamp(0, 6) * 65)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 22 * (1 - value)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => context.push(RoutePaths.review(meal.id)),
          child: SizedBox(
            height: 184,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(fit: StackFit.expand, children: [
                MealPhoto(mealId: meal.id, hasImage: meal.hasImage, hero: true),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xD9000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(meal.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: Colors.white)),
                            Text(
                                '${meal.type} • ${meal.protein.toStringAsFixed(0)} g protein',
                                style: const TextStyle(color: Colors.white70)),
                          ]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.2),
                          borderRadius: BorderRadius.circular(18)),
                      child: Text('${meal.calories.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

int _key(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

String _friendlyDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  return '${weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}, ${date.year}';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];
