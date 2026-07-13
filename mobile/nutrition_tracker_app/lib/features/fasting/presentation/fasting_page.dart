// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/result/result.dart';
import '../../../core/time/clock_service.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../data/fasting_repository.dart';

class FastingPage extends ConsumerStatefulWidget {
  const FastingPage({super.key});
  @override
  ConsumerState<FastingPage> createState() => _FastingPageState();
}

class _FastingPageState extends ConsumerState<FastingPage> {
  int _targetMinutes = 16 * 60;
  bool _saving = false;
  bool _notifyAtTarget = false;
  late Future<Result<List<FastingHistoryEntry>>> _history;
  @override
  void initState() {
    super.initState();
    _history = ref.read(fastingRepositoryProvider).history();
  }

  String _time(Duration value) =>
      '${value.inHours.toString().padLeft(2, '0')}:${(value.inMinutes % 60).toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  void _message(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(value)));
  Future<void> _start() async {
    if (_notifyAtTarget &&
        !await ref.read(localNotificationServiceProvider).requestPermission()) {
      if (mounted) _message('Notification permission was not granted.');
      return;
    }
    setState(() => _saving = true);
    final result = await ref
        .read(fastingControllerProvider.notifier)
        .start(_targetMinutes);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is Failure<ActiveFast>) {
      _message(result.failure.message);
    } else if (_notifyAtTarget && result is Success<ActiveFast>) {
      await ref.read(localNotificationServiceProvider).scheduleAt(
          id: _notificationId(result.value),
          whenLocal: result.value.plannedEndAtUtc.toLocal(),
          title: 'Fasting target complete',
          body: 'Your selected fasting target is complete.');
    }
  }

  Future<void> _finish(bool cancel) async {
    final fast = ref.read(fastingControllerProvider).valueOrNull;
    if (fast == null) return;
    final confirmed = await showModalBottomSheet<bool>(
        context: context,
        builder: (sheet) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(cancel ? 'Cancel this fast?' : 'End this fast?',
                      style: Theme.of(sheet).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(cancel
                      ? 'It will not be added to completed fasting history.'
                      : 'Elapsed: ${_time(fast.elapsed(ref.read(clockProvider)))}'),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: () => Navigator.pop(sheet, true),
                      child: Text(cancel ? 'Cancel fast' : 'End fast')),
                  TextButton(
                      onPressed: () => Navigator.pop(sheet, false),
                      child: const Text('Keep fasting'))
                ]))));
    if (confirmed != true) return;
    setState(() => _saving = true);
    final result = cancel
        ? await ref.read(fastingControllerProvider.notifier).cancel()
        : await ref.read(fastingControllerProvider.notifier).end();
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is Failure<ActiveFast>)
      _message(result.failure.message);
    else if (result is Success<ActiveFast>) {
      await ref
          .read(localNotificationServiceProvider)
          .cancel(_notificationId(fast));
      _message(cancel
          ? 'Fast cancelled.'
          : result.value.pendingEnd
              ? 'End saved locally. It will sync when you reconnect.'
              : 'Fast completed and saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fastingControllerProvider);
    final clock = ref.watch(clockProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Fasting timer')),
        body: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
                child: FilledButton(
                    onPressed: () =>
                        ref.read(fastingControllerProvider.notifier).load(),
                    child: const Text('Retry'))),
            data: (fast) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(fastingControllerProvider.notifier).load(),
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  ...(fast == null
                      ? _inactive(context)
                      : _active(context, fast, clock)),
                  const SizedBox(height: 28),
                  const Text('Recent fasts',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  FutureBuilder<Result<List<FastingHistoryEntry>>>(
                      future: _history,
                      builder: (context, snapshot) {
                        final result = snapshot.data;
                        if (result is Success<List<FastingHistoryEntry>>)
                          return Column(
                              children: result.value.isEmpty
                                  ? const [
                                      ListTile(
                                          title:
                                              Text('No completed fasts yet.'))
                                    ]
                                  : result.value
                                      .map((entry) => ListTile(
                                          leading: Icon(
                                              entry.status == 'Completed'
                                                  ? Icons.check_circle_outline
                                                  : Icons.cancel_outlined),
                                          title: Text(
                                              '${entry.durationMinutes ~/ 60}h ${entry.durationMinutes % 60}m'),
                                          subtitle: Text(
                                              '${entry.status} · ${TimeOfDay.fromDateTime(entry.startedAtUtc).format(context)}'),
                                          trailing: entry.endedAtUtc == null
                                              ? null
                                              : Text(
                                                  '${entry.endedAtUtc!.day}/${entry.endedAtUtc!.month}')))
                                      .toList());
                        return const SizedBox.shrink();
                      }),
                  const SizedBox(height: 16),
                  const Text(
                      'Fasting tracking is for informational purposes only. It is not medical advice. Stop fasting and seek professional guidance if you feel unwell.',
                      style:
                          TextStyle(color: AppColors.mutedText, fontSize: 12))
                ]))));
  }

  List<Widget> _inactive(BuildContext context) => [
        Text('Start a fast', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
            'Choose a personal tracking target. These are not recommendations.'),
        const SizedBox(height: 24),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final hours in const [12, 14, 16, 18, 20])
            ChoiceChip(
                label: Text('$hours hours'),
                selected: _targetMinutes == hours * 60,
                onSelected: (_) => setState(() => _targetMinutes = hours * 60)),
          ChoiceChip(
              label: const Text('Custom'),
              selected:
                  !const [720, 840, 960, 1080, 1200].contains(_targetMinutes),
              onSelected: (_) => _custom())
        ]),
        SwitchListTile.adaptive(
            value: _notifyAtTarget,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(() => _notifyAtTarget = value),
            title: const Text('Notify when target is reached'),
            subtitle:
                const Text('One optional, informational device notification.')),
        const SizedBox(height: 16),
        FilledButton.icon(
            onPressed: _saving ? null : _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(_saving
                ? 'Starting…'
                : 'Start ${_targetMinutes ~/ 60}-hour fast'))
      ];
  Future<void> _custom() async {
    final text = TextEditingController(text: (_targetMinutes ~/ 60).toString());
    final hours = await showDialog<int>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Custom target'),
                content: TextField(
                    controller: text,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Hours (1–72)')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(dialog, int.tryParse(text.text)),
                      child: const Text('Save'))
                ]));
    text.dispose();
    if (hours != null && hours >= 1 && hours <= 72)
      setState(() => _targetMinutes = hours * 60);
  }

  List<Widget> _active(
      BuildContext context, ActiveFast fast, ClockService clock) {
    final elapsed = fast.elapsed(clock);
    final reached = fast.reached(clock);
    final progress =
        (elapsed.inSeconds / Duration(minutes: fast.targetMinutes).inSeconds)
            .clamp(0, 1)
            .toDouble();
    return [
      Text(reached ? 'Target reached' : 'Fast in progress',
          style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      Center(
          child: SizedBox(
              width: 230,
              height: 230,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                    child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 14,
                        color: reached ? AppColors.green : AppColors.cyan,
                        backgroundColor: AppColors.cyan.withOpacity(.14))),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_time(elapsed),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Text('elapsed')
                ])
              ]))),
      const SizedBox(height: 24),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target: ${fast.targetMinutes ~/ 60}:00'),
                    Text(reached
                        ? '${_time(elapsed - Duration(minutes: fast.targetMinutes))} over target'
                        : '${_time(fast.remaining(clock))} remaining'),
                    Text(
                        'Started ${TimeOfDay.fromDateTime(fast.startedAtUtc.toLocal()).format(context)}')
                  ]))),
      if (fast.pendingEnd)
        const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
                'End pending sync. Keep this app signed in until it reconnects.',
                style: TextStyle(color: AppColors.warning))),
      const SizedBox(height: 20),
      FilledButton.icon(
          onPressed: _saving || fast.pendingEnd ? null : () => _finish(false),
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('End fast')),
      TextButton(
          onPressed: _saving || fast.pendingEnd ? null : () => _finish(true),
          child: const Text('Cancel fast'))
    ];
  }

  int _notificationId(ActiveFast fast) => fast.id.hashCode & 0x7fffffff;
}
