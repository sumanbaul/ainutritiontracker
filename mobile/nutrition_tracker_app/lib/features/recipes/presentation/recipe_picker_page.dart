import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
import '../data/recipe_repository.dart';
import '../../meal_capture/domain/meal_review.dart';

class RecipePickerPage extends ConsumerStatefulWidget {
  const RecipePickerPage({super.key});
  @override
  ConsumerState<RecipePickerPage> createState() => _RecipePickerPageState();
}

class _RecipePickerPageState extends ConsumerState<RecipePickerPage> {
  String query = '';
  late Future<Result<List<RecipeSummary>>> future;
  @override
  void initState() {
    super.initState();
    future = ref.read(recipeRepositoryProvider).list();
  }

  Future<void> refresh() async {
    setState(
        () => future = ref.read(recipeRepositoryProvider).list(refresh: true));
    await future;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Saved recipes')),
      body: RefreshIndicator(
          onRefresh: refresh,
          child: FutureBuilder<Result<List<RecipeSummary>>>(
              future: future,
              builder: (context, snapshot) {
                final recipes = snapshot.data is Success<List<RecipeSummary>>
                    ? (snapshot.data as Success<List<RecipeSummary>>)
                        .value
                        .where((x) =>
                            x.name.toLowerCase().contains(query.toLowerCase()))
                        .toList()
                    : <RecipeSummary>[];
                return ListView(padding: const EdgeInsets.all(16), children: [
                  TextField(
                      onChanged: (value) => setState(() => query = value),
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Search recipes')),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const LinearProgressIndicator(),
                  if (snapshot.data is Failure)
                    const ListTile(
                        title: Text(
                            'Recipes could not be loaded. Pull to retry.')),
                  if (snapshot.connectionState != ConnectionState.waiting &&
                      recipes.isEmpty)
                    const ListTile(title: Text('No saved recipes yet.')),
                  ...recipes.map((recipe) => Card(
                          child: ExpansionTile(
                              title: Text(recipe.name),
                              subtitle: Text(
                                  '${recipe.caloriesPerServing.round()} kcal per serving'),
                              children: [
                            ...recipe.ingredients.map((x) => ListTile(
                                dense: true,
                                title:
                                    Text(x['food'] as String? ?? 'Ingredient'),
                                trailing: Text('${x['grams']} g'))),
                            FilledButton.icon(
                                onPressed: () async {
                                  final result = await ref
                                      .read(recipeRepositoryProvider)
                                      .createMeal(recipe, 1);
                                  if (result is Success<MealReview> &&
                                      context.mounted) {
                                    context.push(
                                        RoutePaths.review(result.value.mealId));
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Log 1 serving'))
                          ])))
                ]);
              })));
}
