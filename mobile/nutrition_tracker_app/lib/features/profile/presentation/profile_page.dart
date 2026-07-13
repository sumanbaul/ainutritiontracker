import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/result/result.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late Future<Result<UserProfile?>> future;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = ref.read(profileRepositoryProvider).get();
  }

  Future<void> edit(UserProfile p) async {
    final name = TextEditingController(text: p.name),
        current = TextEditingController(text: p.currentWeight.toString()),
        target = TextEditingController(text: p.targetWeight.toString());
    final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Edit profile'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: current,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Current weight (kg)')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: target,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Target weight (kg)'))
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Save'))
                ]));
    if (save == true) {
      await ref.read(profileRepositoryProvider).update({
        'name': name.text.trim(),
        'dateOfBirth': p.dateOfBirth.toIso8601String().split('T').first,
        'biologicalSex': p.biologicalSex,
        'heightCm': p.height,
        'currentWeightKg': double.tryParse(current.text),
        'targetWeightKg': double.tryParse(target.text),
        'activityLevel': p.activity,
        'goalType': p.goal,
        'dietPreference': p.diet,
        'preferredMeasurementSystem': p.measurement,
        'timezone': p.timezone,
        'customCalories': null,
        'customProteinGrams': null,
        'customCarbohydrateGrams': null,
        'customFatGrams': null
      });
      if (mounted) {
        setState(load);
      }
    }
    name.dispose();
    current.dispose();
    target.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Result<UserProfile?>>(
      future: future,
      builder: (context, s) {
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final r = s.data!;
        if (r is! Success<UserProfile?> || r.value == null) {
          return const Center(
              child: Text('Complete onboarding to create your profile.'));
        }
        final p = r.value!;
        return SafeArea(
            bottom: false,
            child: RefreshIndicator(
                onRefresh: () async {
                  setState(load);
                  await future;
                },
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 116),
                    children: [
                      CircleAvatar(
                          radius: 36,
                          child: Text(p.name.characters.first.toUpperCase())),
                      const SizedBox(height: 12),
                      Text(p.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall),
                      TextButton.icon(
                          onPressed: () => edit(p),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit profile and goals')),
                      Card(
                          child: Column(children: [
                        ListTile(
                            title: const Text('Current weight'),
                            trailing: Text(
                                '${p.currentWeight.toStringAsFixed(1)} kg')),
                        ListTile(
                            title: const Text('Target weight'),
                            trailing: Text(
                                '${p.targetWeight.toStringAsFixed(1)} kg')),
                        ListTile(
                            title: const Text('Height'),
                            trailing:
                                Text('${p.height.toStringAsFixed(1)} cm')),
                        ListTile(
                            title: const Text('Goal'), trailing: Text(p.goal)),
                        ListTile(
                            title: const Text('Activity'),
                            trailing: Text(p.activity)),
                        ListTile(
                            title: const Text('Diet'), trailing: Text(p.diet))
                      ])),
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('NUTRITION PROTOCOL'),
                                    Text(
                                        '${p.target.calories.toStringAsFixed(0)} kcal • ${p.target.protein.toStringAsFixed(0)} g protein'),
                                    Text(
                                        'BMR ${p.target.bmr.toStringAsFixed(0)} • TDEE ${p.target.tdee.toStringAsFixed(0)}')
                                  ])))
                    ])));
      });
}
