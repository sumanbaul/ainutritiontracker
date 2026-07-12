import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/result/result.dart';
import '../data/meal_history_repository.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  late Future<Result<List<MealHistoryItem>>> future;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = ref.read(mealHistoryRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    setState(load);
    await future;
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
      onRefresh: refresh,
      child: FutureBuilder<Result<List<MealHistoryItem>>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return ListView(children: const [
                SizedBox(height: 260),
                Center(child: CircularProgressIndicator())
              ]);
            }
            final result = snapshot.data!;
            if (result is! Success<List<MealHistoryItem>>) {
              return ListView(children: const [
                SizedBox(height: 240),
                Center(
                    child: Text('Meal history sync failed.\nPull to retry.',
                        textAlign: TextAlign.center))
              ]);
            }
            if (result.value.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 240),
                Center(
                    child: Text(
                        'No meal records found\nYour confirmed meals will appear here.',
                        textAlign: TextAlign.center))
              ]);
            }
            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: result.value.length,
                itemBuilder: (context, index) {
                  final meal = result.value[index];
                  return Card(
                      child: ListTile(
                          leading: const Icon(Icons.bolt),
                          title: Text(meal.name),
                          subtitle: Text(
                              '${meal.type} • ${meal.protein.toStringAsFixed(0)} g protein'),
                          trailing: Text(
                              '${meal.calories.toStringAsFixed(0)} kcal')));
                });
          }));
}
