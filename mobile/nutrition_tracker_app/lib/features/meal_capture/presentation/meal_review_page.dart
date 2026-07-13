import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/result/result.dart';
import '../../../shared/presentation/glass_surface.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../meal_history/data/meal_history_repository.dart';
import '../data/meal_repository.dart';
import '../domain/meal_review.dart';
import 'meal_photo.dart';

class MealReviewPage extends ConsumerStatefulWidget {
  const MealReviewPage({required this.mealId, super.key});
  final String mealId;
  @override
  ConsumerState<MealReviewPage> createState() => _MealReviewPageState();
}

class _MealReviewPageState extends ConsumerState<MealReviewPage> {
  late Future<Result<MealReview>> _future;
  bool _confirming = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      _future = ref.read(mealRepositoryProvider).review(widget.mealId);
  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    final result =
        await ref.read(mealRepositoryProvider).confirm(widget.mealId);
    if (!mounted) return;
    setState(() => _confirming = false);
    if (result is Success<MealReview>) {
      ref.invalidate(dashboardRepositoryProvider);
      ref.invalidate(mealHistoryRepositoryProvider);
      context.go(RoutePaths.home);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Meal confirmed. Today has been refreshed.')));
    }
  }

  Future<void> _edit(MealReviewItem item) async {
    final grams =
        TextEditingController(text: (item.grams ?? 0).toStringAsFixed(0));
    final saved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Edit ${item.detectedName}'),
                content: TextField(
                    controller: grams,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Grams')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save'))
                ]));
    if (saved == true) {
      await ref.read(mealRepositoryProvider).updateItem(widget.mealId, item,
          grams: double.tryParse(grams.text) ?? 0,
          preparationMethod: item.preparationMethod);
      await _refresh();
    }
    grams.dispose();
  }

  Future<void> _addFood() async {
    final query = TextEditingController();
    final grams = TextEditingController(text: '100');
    var foods = <FoodSearchItem>[];
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) => Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: query,
                      decoration:
                          const InputDecoration(labelText: 'Search food'),
                      onSubmitted: (_) async {
                        final result = await ref
                            .read(mealRepositoryProvider)
                            .searchFoods(query.text);
                        if (result is Success<List<FoodSearchItem>>) {
                          setSheetState(() => foods = result.value);
                        }
                      }),
                  const SizedBox(height: 10),
                  TextField(
                      controller: grams,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Grams')),
                  ...foods.map((food) => ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                          '${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100 g'),
                      onTap: () async {
                        await ref.read(mealRepositoryProvider).addItem(
                            widget.mealId,
                            foodId: food.id,
                            grams: double.tryParse(grams.text) ?? 0,
                            preparationMethod: 'Unknown');
                        if (context.mounted) Navigator.pop(context);
                        await _refresh();
                      }))
                ]))));
    query.dispose();
    grams.dispose();
  }

  Future<void> _corrections() async {
    final result =
        await ref.read(mealRepositoryProvider).corrections(widget.mealId);
    if (!mounted) return;
    await showModalBottomSheet<void>(
        context: context,
        builder: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: result is Success<List<MealCorrection>> &&
                    result.value.isNotEmpty
                ? ListView(shrinkWrap: true, children: [
                    Text('Correction history',
                        style: Theme.of(context).textTheme.titleLarge),
                    ...result.value.map((entry) => ListTile(
                        title: Text(entry.type),
                        subtitle: Text(
                            '${entry.predictedGrams?.toStringAsFixed(0) ?? '-'} g to ${entry.correctedGrams?.toStringAsFixed(0) ?? '-'} g')))
                  ])
                : const SizedBox(
                    height: 100,
                    child:
                        Center(child: Text('No corrections recorded yet.')))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          foregroundColor: Colors.white,
          title: const Text('Food details'),
          centerTitle: true),
      body: FutureBuilder<Result<MealReview>>(
          future: _future,
          builder: (context, snapshot) {
            final result = snapshot.data;
            if (result == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (result is! Success<MealReview>) {
              return Center(
                  child: TextButton(
                      onPressed: _refresh,
                      child: const Text('Review unavailable — retry')));
            }
            final meal = result.value;
            return Stack(fit: StackFit.expand, children: [
              Positioned.fill(
                  bottom: MediaQuery.sizeOf(context).height * .34,
                  child: MealPhoto(
                      mealId: meal.mealId,
                      hasImage: meal.hasImage,
                      hero: true)),
              DraggableScrollableSheet(
                  initialChildSize: .64,
                  minChildSize: .48,
                  maxChildSize: .88,
                  snap: true,
                  builder: (context, controller) => GlassSurface(
                      padding: EdgeInsets.zero,
                      radius: 34,
                      blur: 30,
                      opacity: Theme.of(context).brightness == Brightness.dark
                          ? .9
                          : .8,
                      child: Column(children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView(
                              controller: controller,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 10, 20, 20),
                              children: [
                                Center(
                                    child: Container(
                                        width: 44,
                                        height: 5,
                                        decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                            borderRadius:
                                                BorderRadius.circular(9)))),
                                const SizedBox(height: 18),
                                Text(meal.name ?? 'Meal analysis',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium),
                                const SizedBox(height: 14),
                                _energy(context, meal),
                                const SizedBox(height: 12),
                                Wrap(spacing: 9, runSpacing: 9, children: [
                                  _macro(context, 'Carbs', meal.totalCarbs,
                                      AppColors.warning),
                                  _macro(context, 'Protein', meal.totalProtein,
                                      AppColors.green),
                                  _macro(context, 'Fat', meal.totalFat,
                                      AppColors.cyan),
                                  _macro(context, 'Fibre', meal.totalFibre,
                                      AppColors.violet)
                                ]),
                                const SizedBox(height: 14),
                                Text(
                                    meal.provider.toLowerCase() == 'mock'
                                        ? 'Simulated analysis — review every estimate.'
                                        : '${meal.provider}${meal.model == null ? '' : ' • ${meal.model}'} analysis',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.softInk,
                                        fontWeight: FontWeight.w600)),
                                if (meal.warnings.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                          color: AppColors.warning
                                              .withOpacity(.14),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text(meal.warnings.first)),
                                ],
                                const SizedBox(height: 22),
                                Text('Detected foods',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                ...meal.items.map((item) => _item(item)),
                                OutlinedButton.icon(
                                    onPressed: _addFood,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add food item')),
                                TextButton.icon(
                                    onPressed: _corrections,
                                    icon: const Icon(Icons.history),
                                    label: const Text('Correction history')),
                              ],
                            ),
                          ),
                        ),
                        SafeArea(
                          top: false,
                          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  meal.status == 'Confirmed' || _confirming
                                      ? null
                                      : _confirm,
                              icon: _confirming
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(_confirming
                                  ? 'Confirming meal'
                                  : meal.status == 'Confirmed'
                                      ? 'Meal confirmed'
                                      : 'Confirm meal'),
                            ),
                          ),
                        ),
                      ])))
            ]);
          }));

  Widget _item(MealReviewItem item) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      title: Text(item.detectedName,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
          '${item.grams?.toStringAsFixed(0) ?? '?'} g  •  ${item.calories.toStringAsFixed(0)} kcal\nRecognition ${(item.recognitionConfidence * 100).toStringAsFixed(0)}%  •  nutrition ${(item.nutritionMatchConfidence * 100).toStringAsFixed(0)}%'),
      trailing: PopupMenuButton<String>(
          onSelected: (choice) async {
            if (choice == 'edit') await _edit(item);
            if (choice == 'remove') {
              await ref
                  .read(mealRepositoryProvider)
                  .removeItem(widget.mealId, item.id);
              await _refresh();
            }
          },
          itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit grams')),
                PopupMenuItem(value: 'remove', child: Text('Remove'))
              ]));

  Widget _energy(BuildContext context, MealReview meal) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(.62),
          borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        const Icon(Icons.local_fire_department, color: AppColors.danger),
        const SizedBox(width: 9),
        const Expanded(
            child: Text('Total energy', overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: AnimatedCount(meal.totalCalories,
                suffix: ' kcal', style: Theme.of(context).textTheme.titleLarge),
          ),
        )
      ]));

  Widget _macro(
          BuildContext context, String label, double value, Color color) =>
      Container(
          width: (MediaQuery.sizeOf(context).width - 70) / 2,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(.56),
              borderRadius: BorderRadius.circular(21)),
          child: Row(children: [
            Icon(Icons.circle, size: 11, color: color),
            const SizedBox(width: 7),
            Expanded(child: Text(label)),
            Text('${value.toStringAsFixed(0)}g',
                style: const TextStyle(fontWeight: FontWeight.w800))
          ]));
}
