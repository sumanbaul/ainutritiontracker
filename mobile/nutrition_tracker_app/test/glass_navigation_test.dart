import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/app/theme/app_theme.dart';
import 'package:nutrition_tracker_app/shared/presentation/app_shell.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'floating glass navigation exposes and selects all destinations in ${dark ? 'dark' : 'light'} mode',
        (tester) async {
      var selected = 0;
      await tester.pumpWidget(MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Text('selected $selected'),
            bottomNavigationBar: GlassNavigationBar(
              index: selected,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ));

      for (final destination in const [
        'Home',
        'Scan',
        'History',
        'Progress',
        'Profile'
      ]) {
        await tester.tap(find.bySemanticsLabel(destination));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('selected 4'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      final decorated = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((box) =>
              box.decoration is BoxDecoration &&
              (box.decoration as BoxDecoration).gradient != null);
      expect(decorated, isNotEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
