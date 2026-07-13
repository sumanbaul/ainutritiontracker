import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/result/result.dart';
import '../../../shared/presentation/nutrition_ui.dart';
import '../data/habit_repository.dart';

class HabitsPage extends ConsumerStatefulWidget {
  const HabitsPage({super.key});
  @override
  ConsumerState<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends ConsumerState<HabitsPage> {
  late Future<Result<HabitSummary>> _summary;
  late Future<Result<List<HabitReminder>>> _reminders;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _summary = ref.read(habitRepositoryProvider).summary('daily');
    _reminders = ref.read(habitRepositoryProvider).reminders();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_summary, _reminders]);
  }

  Future<void> _addWater(double amount) async {
    setState(() => _saving = true);
    final result = await ref.read(habitRepositoryProvider).addWater(amount);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _reload();
    });
    if (result is Failure<void>) _message(result.failure.message);
  }

  Future<void> _logFast() async {
    final hours = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const NutritionSectionTitle('Log a completed fast',
                subtitle: 'Choose the duration ending now.'),
            const SizedBox(height: 18),
            for (final hours in const [12, 14, 16, 18])
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text('$hours-hour fast'),
                onTap: () => Navigator.pop(context, hours),
              ),
          ]),
        ),
      ),
    );
    if (hours == null) return;
    final end = DateTime.now();
    final result = await ref
        .read(habitRepositoryProvider)
        .addFast(end.subtract(Duration(hours: hours)), end);
    if (!mounted) return;
    if (result is Failure<void>) _message(result.failure.message);
    await _refresh();
  }

  Future<void> _addReminder() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 30),
    );
    if (time == null) return;
    if (!mounted) return;
    final formattedTime = time.format(context);
    final notifications = ref.read(localNotificationServiceProvider);
    final permitted = await notifications.requestPermission();
    if (!permitted) {
      if (mounted) _message('Enable notifications in system settings first.');
      return;
    }
    final hhmm =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final result = await ref.read(habitRepositoryProvider).saveReminder(
          type: 'meal',
          localTime: hhmm,
          timezone: DateTime.now().timeZoneName,
          enabled: true,
        );
    if (!mounted) return;
    if (result case Success<HabitReminder>(value: final reminder)) {
      await notifications.scheduleDaily(
        id: reminder.id.hashCode & 0x7fffffff,
        hour: time.hour,
        minute: time.minute,
        title: 'Time to check in',
        body: 'Log your meal and keep today’s nutrition plan on track.',
      );
      if (!mounted) return;
      _message('Daily reminder scheduled for $formattedTime.');
      await _refresh();
    } else if (result case Failure<HabitReminder>(failure: final failure)) {
      _message(failure.message);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Habits & routines')),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<Result<HabitSummary>>(
            future: _summary,
            builder: (context, snapshot) {
              final result = snapshot.data;
              if (result == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (result is! Success<HabitSummary>) {
                return ListView(children: const [
                  SizedBox(height: 240),
                  Center(child: Text('Habit data could not be loaded.')),
                ]);
              }
              final summary = result.value;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text('Build your rhythm',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Text('Small daily actions, visible in one place.',
                      style: TextStyle(color: AppColors.secondaryText)),
                  const SizedBox(height: 22),
                  _HabitCard(
                    icon: Icons.water_drop_outlined,
                    color: AppColors.cyan,
                    title: 'Hydration',
                    value:
                        '${(summary.hydrationMillilitres / 1000).toStringAsFixed(2)} L',
                    caption: '2.5 L daily reference',
                    progress: (summary.hydrationMillilitres / 2500).clamp(0, 1),
                    action: FilledButton.tonalIcon(
                      onPressed: _saving ? null : () => _addWater(250),
                      icon: const Icon(Icons.add),
                      label: const Text('250 ml'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _HabitCard(
                    icon: Icons.timer_outlined,
                    color: AppColors.violet,
                    title: 'Fasting',
                    value: '${summary.fastingMinutes ~/ 60}h '
                        '${summary.fastingMinutes % 60}m',
                    caption: 'Completed fasting time today',
                    progress: (summary.fastingMinutes / (16 * 60)).clamp(0, 1),
                    action: OutlinedButton.icon(
                      onPressed: _logFast,
                      icon: const Icon(Icons.add),
                      label: const Text('Log fast'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  NutritionSectionTitle('Daily reminders',
                      subtitle: 'Scheduled locally on this device.',
                      action: IconButton.filledTonal(
                          onPressed: _addReminder,
                          icon: const Icon(Icons.add_alarm_outlined))),
                  const SizedBox(height: 10),
                  FutureBuilder<Result<List<HabitReminder>>>(
                    future: _reminders,
                    builder: (context, snapshot) {
                      final result = snapshot.data;
                      final reminders = result is Success<List<HabitReminder>>
                          ? result.value
                          : const <HabitReminder>[];
                      if (reminders.isEmpty) {
                        return const Card(
                          child: ListTile(
                            leading: Icon(Icons.notifications_none),
                            title: Text('No reminders yet'),
                            subtitle: Text(
                                'Add a daily meal reminder when you are ready.'),
                          ),
                        );
                      }
                      return Column(
                        children: reminders
                            .map((item) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.alarm),
                                    title: Text('${item.type} reminder'),
                                    subtitle:
                                        Text(item.localTime.substring(0, 5)),
                                    trailing: Icon(item.isEnabled
                                        ? Icons.notifications_active_outlined
                                        : Icons.notifications_off_outlined),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hydration and fasting references are informational only. '
                    'Adjust habits for your health needs with a qualified clinician.',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.caption,
    required this.progress,
    required this.action,
  });
  final IconData icon;
  final Color color;
  final String title, value, caption;
  final double progress;
  final Widget action;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: color.withOpacity(.2)),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.15;
          final details = Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(.12), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(caption,
                        style: const TextStyle(color: AppColors.secondaryText)),
                  ]),
            ),
            if (!compact) ...[const SizedBox(width: 8), action],
          ]);
          return Column(children: [
            details,
            if (compact) ...[
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: action),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                color: color,
                backgroundColor: color.withOpacity(.12),
                minHeight: 8,
              ),
            ),
          ]);
        }),
      );
}
