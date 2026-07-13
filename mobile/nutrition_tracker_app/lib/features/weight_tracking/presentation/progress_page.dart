import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/result/result.dart';
import '../data/weight_repository.dart';

class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});
  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  late Future<Result<List<WeightEntry>>> future;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = ref.read(weightRepositoryProvider).getAll();
  }

  Future<void> add() async {
    final controller = TextEditingController();
    final value = await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Log body metric',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Weight (kg)')),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: () => Navigator.pop(
                      sheetContext, double.tryParse(controller.text)),
                  child: const Text('Save weight'))
            ])));
    controller.dispose();
    if (value != null && value >= 25 && value <= 400) {
      await ref.read(weightRepositoryProvider).add(value, null);
      if (mounted) {
        setState(load);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      floatingActionButton: FloatingActionButton.extended(
          onPressed: add,
          icon: const Icon(Icons.add),
          label: const Text('Log weight')),
      body: FutureBuilder<Result<List<WeightEntry>>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final result = snapshot.data!;
            if (result is! Success<List<WeightEntry>>) {
              return const Center(
                  child: Text('Weight history could not be loaded.'));
            }
            if (result.value.isEmpty) {
              return const Center(
                  child: Text(
                      'Start your body-metric timeline\nLog your first weight to track progress.',
                      textAlign: TextAlign.center));
            }
            final entries = result.value;
            final newest = entries.first;
            final oldest = entries.last;
            final change = newest.weightKg - oldest.weightKg;
            final min =
                entries.map((x) => x.weightKg).reduce((a, b) => a < b ? a : b);
            final max =
                entries.map((x) => x.weightKg).reduce((a, b) => a > b ? a : b);
            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Progress',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 12),
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Row(children: [
                                    const Icon(Icons.monitor_weight_outlined),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          const Text('Weight trend'),
                                          Text(
                                              '${newest.weightKg.toStringAsFixed(1)} kg',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall),
                                          Text(
                                              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg across ${entries.length} entries')
                                        ]))
                                  ]))),
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Range'),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                            value: max == min
                                                ? 1
                                                : (newest.weightKg - min) /
                                                    (max - min)),
                                        const SizedBox(height: 8),
                                        Text(
                                            '${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)} kg • trends are informational, not medical advice')
                                      ]))),
                          const SizedBox(height: 8),
                          const Text('History')
                        ]);
                  }
                  final entry = entries[index - 1];
                  return Card(
                      child: ListTile(
                          leading: const Icon(Icons.monitor_weight_outlined),
                          title:
                              Text('${entry.weightKg.toStringAsFixed(1)} kg'),
                          subtitle: Text(MaterialLocalizations.of(context)
                              .formatMediumDate(
                                  entry.recordedAtUtc.toLocal()))));
                });
          }));
}
