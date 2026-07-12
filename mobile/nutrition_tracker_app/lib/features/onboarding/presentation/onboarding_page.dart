import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int step = 0;
  final name = TextEditingController(),
      dob = TextEditingController(text: '1990-01-01'),
      height = TextEditingController(text: '170'),
      weight = TextEditingController(text: '75'),
      target = TextEditingController(text: '70');
  String sex = 'Male',
      goal = 'LoseWeightSlowly',
      activity = 'ModeratelyActive',
      diet = 'NoPreference';
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in [name, dob, height, weight, target]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => busy = true);
    final result = await ref.read(profileRepositoryProvider).create({
      'name': name.text.trim(),
      'dateOfBirth': dob.text,
      'biologicalSex': sex,
      'heightCm': double.tryParse(height.text),
      'currentWeightKg': double.tryParse(weight.text),
      'targetWeightKg': double.tryParse(target.text),
      'activityLevel': activity,
      'goalType': goal,
      'dietPreference': diet,
      'preferredMeasurementSystem': 'Metric',
      'timezone': 'Asia/Kolkata',
      'customCalories': null,
      'customProteinGrams': null,
      'customCarbohydrateGrams': null,
      'customFatGrams': null
    });
    if (!mounted) return;
    setState(() => busy = false);
    if (result is Success<UserProfile>) {
      context.go(RoutePaths.home);
    } else {
      setState(() => error =
          'Nutrition protocol could not be generated. Check all values and retry.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_welcome(), _details(), _choices(), _review()];
    return Scaffold(
        appBar: AppBar(title: Text('Protocol setup ${step + 1}/4')),
        body: SafeArea(
            child: Column(children: [
          LinearProgressIndicator(value: (step + 1) / 4),
          Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24), child: pages[step])),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                if (step > 0)
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => setState(() => step--),
                          child: const Text('Back'))),
                if (step > 0) const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                        onPressed: busy
                            ? null
                            : step == 3
                                ? submit
                                : () => setState(() => step++),
                        child:
                            Text(step == 3 ? 'Generate protocol' : 'Continue')))
              ]))
        ])));
  }

  Widget _welcome() => const Column(children: [
        SizedBox(height: 60),
        Icon(Icons.bolt, size: 96),
        SizedBox(height: 24),
        Text('Scan. Understand. Improve.',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        SizedBox(height: 12),
        Text(
            'Build a nutrition protocol calibrated to your body, goal, and daily rhythm.',
            textAlign: TextAlign.center)
      ]);
  Widget _details() => Column(children: [
        TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 12),
        TextField(
            controller: dob,
            decoration:
                const InputDecoration(labelText: 'Date of birth (YYYY-MM-DD)')),
        const SizedBox(height: 12),
        TextField(
            controller: height,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Height (cm)')),
        const SizedBox(height: 12),
        TextField(
            controller: weight,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Current weight (kg)')),
        const SizedBox(height: 12),
        TextField(
            controller: target,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Target weight (kg)'))
      ]);
  Widget _choices() => Column(children: [
        _drop('Biological sex', sex, ['Male', 'Female', 'Unspecified'],
            (v) => sex = v),
        _drop(
            'Goal',
            goal,
            [
              'MaintainWeight',
              'LoseWeightSlowly',
              'LoseWeightModerately',
              'GainWeightSlowly',
              'GainMuscle'
            ],
            (v) => goal = v),
        _drop(
            'Activity',
            activity,
            [
              'Sedentary',
              'LightlyActive',
              'ModeratelyActive',
              'VeryActive',
              'ExtraActive'
            ],
            (v) => activity = v),
        _drop(
            'Diet',
            diet,
            [
              'NoPreference',
              'Vegetarian',
              'Eggetarian',
              'Vegan',
              'Pescatarian',
              'NonVegetarian'
            ],
            (v) => diet = v)
      ]);
  Widget _drop(String label, String value, List<String> items,
          void Function(String) set) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField(
              value: value,
              decoration: InputDecoration(labelText: label),
              items: items
                  .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                  .toList(),
              onChanged: (v) => setState(() => set(v!))));
  Widget _review() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Nutrition Protocol Ready',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text('${name.text} • ${weight.text} kg → ${target.text} kg'),
        Text('$goal • $activity • $diet'),
        const SizedBox(height: 20),
        const Text('Targets are estimates and are not medical advice.'),
        if (error != null)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child:
                  Text(error!, style: const TextStyle(color: Colors.redAccent)))
      ]);
}
