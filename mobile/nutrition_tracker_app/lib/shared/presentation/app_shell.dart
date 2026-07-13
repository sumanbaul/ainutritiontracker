import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../features/dashboard/presentation/today_page.dart';
import '../../features/meal_capture/presentation/capture_preview_page.dart';
import '../../features/meal_history/presentation/history_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/weight_tracking/presentation/progress_page.dart';
import '../../core/sync/offline_sync_service.dart';
import '../../core/sync/sync_status.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  final _pages = const [
    TodayPage(),
    CapturePreviewPage(),
    HistoryPage(),
    ProgressPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      extendBody: true,
      body: Stack(children: [
        AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(.025, .015), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
        ),
        if (ref.watch(syncStatusProvider).valueOrNull case final status?)
          _SyncBanner(status: status),
      ]),
      bottomNavigationBar: GlassNavigationBar(
        index: _index,
        onChanged: (index) => setState(() => _index = index),
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.status});
  final SyncStatus status;
  @override
  Widget build(BuildContext context) {
    final text = switch (status.state) {
      SyncState.offline => 'Offline — showing saved data',
      SyncState.synchronizing =>
        'Syncing ${status.pendingOperations} change${status.pendingOperations == 1 ? '' : 's'}',
      SyncState.conflict => status.message ?? 'A change needs review',
      SyncState.failed => status.message ?? 'Some changes will retry',
      _ => '',
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return SafeArea(
        child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(.94),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        child: Text(text))))));
  }
}

class GlassNavigationBar extends StatelessWidget {
  const GlassNavigationBar(
      {super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;
  static const items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.document_scanner_outlined, Icons.document_scanner, 'Scan'),
    (Icons.history_outlined, Icons.history_rounded, 'History'),
    (Icons.show_chart_outlined, Icons.show_chart_rounded, 'Progress'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.of(context).disableAnimations;
    final colors = AppSemanticColors.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(dark ? .26 : .13),
                blurRadius: 30,
                offset: const Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: dark
                      ? [
                          Colors.white.withOpacity(.12),
                          colors.glassSurface,
                        ]
                      : [
                          Colors.white.withOpacity(.52),
                          const Color(0xffEDE9FF).withOpacity(.24),
                        ],
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: colors.glassBorder),
              ),
              child: Row(
                children: List.generate(items.length, (itemIndex) {
                  final item = items[itemIndex];
                  final selected = itemIndex == index;
                  final capture = itemIndex == 1;
                  return Expanded(
                    child: Semantics(
                      selected: selected,
                      button: true,
                      label: item.$3,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: () => onChanged(itemIndex),
                        child: AnimatedContainer(
                          duration: reduce
                              ? Duration.zero
                              : const Duration(milliseconds: 360),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: selected
                                ? (capture
                                    ? colors.actionBackground
                                    : colors.actionBackground)
                                : capture
                                    ? colors.foreground.withOpacity(.08)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            selected ? item.$2 : item.$1,
                            color: selected
                                ? colors.actionForeground
                                : (dark
                                    ? AppColors.secondaryText
                                    : AppColors.softInk),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
