import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
import '../data/meal_repository.dart';
import '../domain/meal_review.dart';

class ManualMealPage extends ConsumerStatefulWidget {
  const ManualMealPage({super.key});
  @override
  ConsumerState<ManualMealPage> createState() => _ManualMealPageState();
}

class _ManualMealPageState extends ConsumerState<ManualMealPage> {
  final _name = TextEditingController(text: 'Manual meal');
  final _query = TextEditingController();
  final _grams = TextEditingController(text: '100');
  final List<Map<String, dynamic>> _items = [];
  List<FoodSearchItem> _results = [];
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    _query.dispose();
    _grams.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final r = await ref.read(mealRepositoryProvider).searchFoods(_query.text);
    if (r is Success<List<FoodSearchItem>> && mounted) {
      setState(() => _results = r.value);
    }
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    final r = await ref
        .read(mealRepositoryProvider)
        .createManual(name: _name.text.trim(), items: _items);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (r is Success<MealReview>) {
      context.push(RoutePaths.review(r.value.mealId));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Manual meal')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Meal name')),
        ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Add from saved recipe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RoutePaths.recipes)),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _query,
                  decoration: const InputDecoration(labelText: 'Search food'),
                  onSubmitted: (_) => _search())),
          IconButton(onPressed: _search, icon: const Icon(Icons.search))
        ]),
        TextField(
            controller: _grams,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Grams for selected food')),
        ..._results.map((food) => ListTile(
            title: Text(food.name),
            trailing: const Icon(Icons.add),
            onTap: () {
              final grams = double.tryParse(_grams.text);
              if (grams != null && grams > 0) {
                setState(() {
                  _items.add({
                    'foodId': food.id,
                    'grams': grams,
                    'preparationMethod': 'Unknown'
                  });
                  _results = [];
                });
              }
            })),
        const Divider(),
        ..._items.map((item) => ListTile(
            title: Text('${item['grams']} g'),
            subtitle: Text(item['foodId'] as String),
            trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _items.remove(item))))),
        FilledButton.icon(
            onPressed: _saving || _items.isEmpty ? null : _save,
            icon: const Icon(Icons.arrow_forward),
            label: Text(_saving ? 'Creating…' : 'Review manual meal'))
      ]));
}
