import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/result/result.dart';
import '../../../shared/presentation/glass_ui.dart';
import '../data/discover_meals_repository.dart';

class DiscoverMealsPage extends ConsumerStatefulWidget {
  const DiscoverMealsPage({super.key});
  @override
  ConsumerState<DiscoverMealsPage> createState() => _DiscoverMealsPageState();
}

class _DiscoverMealsPageState extends ConsumerState<DiscoverMealsPage> {
  late Future<Result<DiscoverPlan>> _plan;
  @override
  void initState() {
    super.initState();
    _plan = ref.read(discoverMealsRepositoryProvider).plan();
  }

  Future<void> _refresh({bool regenerate = false}) async {
    setState(() => _plan = regenerate
        ? ref.read(discoverMealsRepositoryProvider).regenerate()
        : ref.read(discoverMealsRepositoryProvider).plan(refresh: true));
    await _plan;
  }

  void _message(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('What to cook')),
      body: FutureBuilder<Result<DiscoverPlan>>(
          future: _plan,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data is! Success<DiscoverPlan>) {
              return Center(
                  child: FilledButton(
                      onPressed: _refresh, child: const Text('Try again')));
            }
            final plan = (snapshot.data! as Success<DiscoverPlan>).value;
            final today = plan.meals
                .where((x) => _sameDay(x.date, DateTime.now()))
                .toList();
            return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                    children: [
                      Text('Your next meal, made simpler',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text(
                          'Reviewed cuisine ideas tailored to your saved diet and exclusions.'),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: FilledButton.icon(
                                onPressed: () => _refresh(regenerate: true),
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('Refresh plan'))),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                            tooltip: 'Add plan to shopping list',
                            onPressed: () async {
                              final result = await ref
                                  .read(discoverMealsRepositoryProvider)
                                  .addPlanToShopping();
                              if (mounted) {
                                _message(result is Success
                                    ? 'Ingredients added to shopping list.'
                                    : 'Could not update shopping list.');
                              }
                            },
                            icon: const Icon(Icons.shopping_basket_outlined)),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                            tooltip: 'Allergen and ingredient exclusions',
                            onPressed: _editExclusions,
                            icon: const Icon(Icons.health_and_safety_outlined)),
                      ]),
                      const SizedBox(height: 22),
                      Text('Today',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      ...today.map((meal) => _RecipeCard(
                          meal: meal,
                          onSave: () async {
                            final result = await ref
                                .read(discoverMealsRepositoryProvider)
                                .save(meal.recipe.id);
                            if (mounted) {
                              _message(result is Success
                                  ? '${meal.recipe.name} saved.'
                                  : 'Could not save recipe.');
                            }
                          })),
                      const SizedBox(height: 18),
                      Text('7-day plan',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      ...plan.meals
                          .where((x) => !_sameDay(x.date, DateTime.now()))
                          .map((meal) => ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              leading: CircleAvatar(
                                  child: Text(meal.slot.substring(0, 1))),
                              title: Text(meal.recipe.name),
                              subtitle: Text(
                                  '${_dayLabel(meal.date)} · ${meal.recipe.cuisine} · ${meal.recipe.calories.round()} kcal'),
                              trailing: const Icon(Icons.chevron_right))),
                      const SizedBox(height: 18),
                      Text(plan.disclaimer,
                          style: TextStyle(
                              color: AppSemanticColors.of(context).muted,
                              fontSize: 12)),
                    ]));
          }));

  Future<void> _editExclusions() async {
    final repository = ref.read(discoverMealsRepositoryProvider);
    final loaded = await repository.exclusions();
    if (!mounted) return;
    final selected =
        loaded is Success<List<String>> ? loaded.value.toSet() : <String>{};
    final custom = TextEditingController();
    const standard = {
      'allergen.milk': 'Milk',
      'allergen.egg': 'Egg',
      'allergen.fish': 'Fish',
      'allergen.shellfish': 'Shellfish',
      'allergen.gluten': 'Gluten',
      'allergen.peanut': 'Peanut',
      'allergen.tree-nut': 'Tree nuts',
      'allergen.soy': 'Soy',
      'allergen.sesame': 'Sesame',
    };
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) => Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
                child: ListView(shrinkWrap: true, children: [
                  Text('Allergen exclusions',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Text(
                      'Only recipes with complete matching ingredient and allergen data are marked safe. Always check labels.'),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8,
                      children: standard.entries
                          .map((entry) => FilterChip(
                              label: Text(entry.value),
                              selected: selected.contains(entry.key),
                              onSelected: (enabled) => setSheetState(() {
                                    if (enabled) {
                                      selected.add(entry.key);
                                    } else {
                                      selected.remove(entry.key);
                                    }
                                  })))
                          .toList()),
                  TextField(
                      controller: custom,
                      decoration: const InputDecoration(
                          labelText: 'Custom ingredient to avoid')),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: () async {
                        if (custom.text.trim().isNotEmpty) {
                          selected.add('ingredient.${custom.text.trim()}');
                        }
                        final result =
                            await repository.saveExclusions(selected);
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.pop(context);
                        _message(result is Success
                            ? 'Exclusions saved. Refreshing your plan.'
                            : 'Could not save exclusions.');
                        if (result is Success) {
                          await _refresh(regenerate: true);
                        }
                      },
                      child: const Text('Save exclusions'))
                ]))));
    custom.dispose();
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.meal, required this.onSave});
  final PlannedDiscoverMeal meal;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Chip(label: Text(meal.slot)),
              const Spacer(),
              Icon(Icons.timer_outlined,
                  size: 17, color: AppPalette.of(context).accent),
              const SizedBox(width: 4),
              Text('${meal.recipe.preparationMinutes} min')
            ]),
            Text(meal.recipe.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(
                '${meal.recipe.cuisine} · ${meal.recipe.calories.round()} kcal · ${meal.recipe.protein.round()} g protein'),
            const SizedBox(height: 10),
            Text('Preparation: ${meal.recipe.preparation.join(' ')}',
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(children: [
              OutlinedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Save')),
              const SizedBox(width: 8),
              TextButton.icon(
                  onPressed: () => _showDetails(context),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Ingredients'))
            ])
          ])));
  void _showDetails(BuildContext context) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
              child: ListView(padding: const EdgeInsets.all(20), children: [
            Text(meal.recipe.name,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('Ingredients',
                style: TextStyle(fontWeight: FontWeight.w800)),
            ...meal.recipe.ingredients.map((x) => ListTile(
                dense: true,
                title: Text(x['name'] as String),
                trailing: Text('${x['quantity']} ${x['unit']}'))),
            const SizedBox(height: 8),
            const Text('Preparation',
                style: TextStyle(fontWeight: FontWeight.w800)),
            ...meal.recipe.preparation.map((x) =>
                ListTile(leading: const Icon(Icons.check), title: Text(x))),
            const Text(
                'AI adaptation is unavailable in this release; preparation facts are catalog-reviewed.',
                style: TextStyle(fontSize: 12))
          ])));
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _dayLabel(DateTime date) => '${date.day}/${date.month}';
