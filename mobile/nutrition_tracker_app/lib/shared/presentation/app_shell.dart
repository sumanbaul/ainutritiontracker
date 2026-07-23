import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  bool _compactNavigation = false;
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
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis != Axis.vertical ||
              notification is! UserScrollNotification) return false;
          final compact = switch (notification.direction) {
            ScrollDirection.reverse => true,
            ScrollDirection.forward => false,
            _ => _compactNavigation,
          };
          if (compact != _compactNavigation) {
            setState(() => _compactNavigation = compact);
          }
          return false;
        },
        child: Stack(children: [
          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween(begin: const Offset(.025, .015), end: Offset.zero)
                        .animate(CurvedAnimation(
                            parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
          ),
          if (ref.watch(syncStatusProvider).valueOrNull case final status?)
            _SyncBanner(status: status),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassNavigationBar(
              index: _index,
              compact: _compactNavigation,
              onChanged: (index) => setState(() {
                _index = index;
                _compactNavigation = false;
              }),
            ),
          ),
        ]),
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
      {super.key,
      required this.index,
      required this.onChanged,
      this.compact = false});
  final int index;
  final ValueChanged<int> onChanged;
  final bool compact;
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
    final palette = AppPalette.of(context);
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 320);
    final height = compact ? 58.0 : 70.0;
    final radius = height / 2;
    return SafeArea(
      minimum: EdgeInsets.fromLTRB(18, 0, 18, compact ? 8 : 12),
      child: LayoutBuilder(builder: (context, constraints) {
        return Align(
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            width: compact ? constraints.maxWidth * .86 : constraints.maxWidth,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(dark ? .30 : .15),
                    blurRadius: compact ? 22 : 30,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dark
                          ? [Colors.white.withOpacity(.12), colors.glassSurface]
                          : [
                              Colors.white.withOpacity(.52),
                              const Color(0xffEDE9FF).withOpacity(.24),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: colors.glassBorder),
                  ),
                  child: LayoutBuilder(builder: (context, inner) {
                    final cellWidth = inner.maxWidth / items.length;
                    return Stack(children: [
                      AnimatedPositioned(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        left: index * cellWidth + 5,
                        top: compact ? 6 : 8,
                        width: cellWidth - 10,
                        height: height - (compact ? 12 : 16),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.accent.withOpacity(dark ? .34 : .18),
                            borderRadius: BorderRadius.circular(radius),
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(items.length, (itemIndex) {
                          final item = items[itemIndex];
                          final selected = itemIndex == index;
                          return Expanded(
                            child: Semantics(
                              selected: selected,
                              button: true,
                              label: item.$3,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(radius),
                                onTap: () => onChanged(itemIndex),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: duration,
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(
                                            scale: animation, child: child),
                                    child: Icon(selected ? item.$2 : item.$1,
                                        key: ValueKey('$itemIndex-$selected'),
                                        size: compact ? 24 : 27,
                                        color: selected
                                            ? palette.accent
                                            : (dark
                                                ? AppColors.secondaryText
                                                : AppColors.softInk)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ]);
                  }),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
