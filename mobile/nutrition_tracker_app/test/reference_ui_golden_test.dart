import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/app/theme/app_theme.dart';
import 'package:nutrition_tracker_app/features/meal_history/data/meal_history_repository.dart';
import 'package:nutrition_tracker_app/features/meal_history/presentation/history_page.dart';
import 'package:nutrition_tracker_app/shared/presentation/app_shell.dart';

void main() {
  testWidgets('floating glass dock light and dark golden', (tester) async {
    tester.view.physicalSize = const Size(860, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [
        Expanded(child: _dock(AppTheme.light())),
        Expanded(child: _dock(AppTheme.dark())),
      ]),
    ));
    await tester.pumpAndSettle();

    await expectLater(find.byType(Row).first,
        matchesGoldenFile('goldens/glass_dock_light_dark.png'));
  });

  testWidgets('history activity grid light and dark golden', (tester) async {
    tester.view.physicalSize = const Size(860, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final start = DateTime(2026, 6, 15);
    final days = List.generate(29, (index) {
      final date = start.add(Duration(days: index));
      final count = index % 5;
      return MealActivityDay(
        date: date,
        startUtc: date.toUtc(),
        endUtc: date.add(const Duration(days: 1)).toUtc(),
        mealCount: count,
        calories: count * 520,
        targetCalories: 2200,
        adherencePercent: count == 0 ? null : count * 23,
      );
    });
    final activity = MealActivity(
      fromDate: days.first.date,
      toDate: days.last.date,
      timezone: 'Asia/Kolkata',
      days: days,
    );

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [
        Expanded(child: _heatmap(AppTheme.light(), activity)),
        Expanded(child: _heatmap(AppTheme.dark(), activity)),
      ]),
    ));
    await tester.pumpAndSettle();

    await expectLater(find.byType(Row).first,
        matchesGoldenFile('goldens/history_heatmap_light_dark.png'));
  });
}

Widget _dock(ThemeData theme) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        extendBody: true,
        body: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.primary),
          child: SizedBox.expand(),
        ),
        bottomNavigationBar: GlassNavigationBar(index: 2, onChanged: (_) {}),
      ),
    );

Widget _heatmap(ThemeData theme, MealActivity activity) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: ActivityHeatmap(
            activity: activity,
            metric: ActivityMetric.meals,
            selectedDate: DateTime(2026, 7, 1),
            onSelected: (_) {},
          ),
        ),
      ),
    );
