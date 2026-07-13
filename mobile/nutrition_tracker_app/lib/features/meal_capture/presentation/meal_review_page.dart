import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../meal_history/data/meal_history_repository.dart';
import '../data/meal_repository.dart';
import '../domain/meal_review.dart';

class MealReviewPage extends ConsumerStatefulWidget {
  const MealReviewPage({required this.mealId, super.key});
  final String mealId;
  @override
  ConsumerState<MealReviewPage> createState() => _MealReviewPageState();
}

class _MealReviewPageState extends ConsumerState<MealReviewPage> {
  late Future<Result<MealReview>> _future;
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
    final r = await ref.read(mealRepositoryProvider).confirm(widget.mealId);
    if (!mounted) return;
    if (r is Success<MealReview>) {
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
        builder: (c) => AlertDialog(
                title: Text('Edit ${item.detectedName}'),
                content: TextField(
                    controller: grams,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Grams')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
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
    List<FoodSearchItem> foods = [];
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
                        final r = await ref
                            .read(mealRepositoryProvider)
                            .searchFoods(query.text);
                        if (r is Success<List<FoodSearchItem>>) {
                          setSheetState(() => foods = r.value);
                        }
                      }),
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
    final r = await ref.read(mealRepositoryProvider).corrections(widget.mealId);
    if (!mounted) return;
    await showModalBottomSheet<void>(
        context: context,
        builder: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: r is Success<List<MealCorrection>> && r.value.isNotEmpty
                ? ListView(shrinkWrap: true, children: [
                    const Text('Correction history'),
                    ...r.value.map((x) => ListTile(
                        title: Text(x.type),
                        subtitle: Text(
                            '${x.predictedGrams?.toStringAsFixed(0) ?? '-'} g to ${x.correctedGrams?.toStringAsFixed(0) ?? '-'} g')))
                  ])
                : const SizedBox(
                    height: 100,
                    child:
                        Center(child: Text('No corrections recorded yet.')))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Review meal')),
      body: FutureBuilder<Result<MealReview>>(
          future: _future,
          builder: (context, s) {
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final r = s.data!;
            if (r is! Success<MealReview>) {
              return Center(
                  child: TextButton(
                      onPressed: _refresh,
                      child: const Text('Review unavailable - retry')));
            }
            final meal = r.value;
            return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Text(meal.name ?? 'Meal analysis',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            Row(children: [
                              Icon(Icons.restaurant_menu,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(meal.status,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge)),
                              Text(
                                  '${meal.totalCalories.toStringAsFixed(0)} kcal',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall)
                            ]),
                            const SizedBox(height: 14),
                            Row(children: [
                              _macro(context, 'Protein', meal.totalProtein,
                                  Colors.purple),
                              _macro(
                                  context, 'Fat', meal.totalFat, Colors.blue),
                              _macro(context, 'Carbs', meal.totalCarbs,
                                  Colors.orange),
                              _macro(context, 'Fibre', meal.totalFibre,
                                  Colors.green)
                            ])
                          ]))),
                  Text(
                    meal.provider.toLowerCase() == 'mock'
                        ? 'Simulated analysis — review and edit all items.'
                        : 'Analysis provider: ${meal.provider}${meal.model == null ? '' : ' • ${meal.model}'}',
                    style: TextStyle(
                        color: meal.provider.toLowerCase() == 'mock'
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.secondary),
                  ),
                  if (meal.warnings.isNotEmpty)
                    Card(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child:
                                Text('Review note: ${meal.warnings.first}'))),
                  ...meal.items.map((item) => Card(
                      child: ListTile(
                          title: Text(item.detectedName),
                          subtitle: Text(
                              '${item.grams?.toStringAsFixed(0) ?? '?'} g • ${item.calories.toStringAsFixed(0)} kcal\nConfidence ${(item.recognitionConfidence * 100).toStringAsFixed(0)}% • nutrition match ${(item.nutritionMatchConfidence * 100).toStringAsFixed(0)}%'),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                              onSelected: (x) async {
                                if (x == 'edit') {
                                  await _edit(item);
                                }
                                if (x == 'remove') {
                                  await ref
                                      .read(mealRepositoryProvider)
                                      .removeItem(widget.mealId, item.id);
                                  await _refresh();
                                }
                              },
                              itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit grams')),
                                    PopupMenuItem(
                                        value: 'remove', child: Text('Remove'))
                                  ])))),
                  OutlinedButton.icon(
                      onPressed: _addFood,
                      icon: const Icon(Icons.add),
                      label: const Text('Add food item')),
                  TextButton.icon(
                      onPressed: _corrections,
                      icon: const Icon(Icons.history),
                      label: const Text('Correction history')),
                  FilledButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm meal'))
                ]));
          }));

  Widget _macro(
          BuildContext context, String label, double value, Color color) =>
      Expanded(
          child: Column(children: [
        Icon(Icons.circle, size: 14, color: color),
        const SizedBox(height: 4),
        Text(label),
        Text('${value.toStringAsFixed(0)} g',
            style: Theme.of(context).textTheme.titleMedium)
      ]));
}
