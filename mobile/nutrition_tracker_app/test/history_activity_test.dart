import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/app/theme/app_theme.dart';
import 'package:nutrition_tracker_app/core/networking/api_client.dart';
import 'package:nutrition_tracker_app/core/result/result.dart';
import 'package:nutrition_tracker_app/features/meal_history/data/meal_history_repository.dart';
import 'package:nutrition_tracker_app/features/meal_history/presentation/history_page.dart';

class _HistoryRepository extends MealHistoryRepository {
  _HistoryRepository(this.activity) : super(ApiClient(Dio()));

  final MealActivity activity;
  int rangeCalls = 0;

  @override
  Future<Result<MealActivity>> getActivity(
          DateTime fromDate, DateTime toDate) async =>
      Success(activity);

  @override
  Future<Result<List<MealHistoryItem>>> getAll() async => const Success([]);

  @override
  Future<Result<List<MealHistoryItem>>> getRange(
      DateTime startUtc, DateTime endUtc) async {
    rangeCalls++;
    return const Success([]);
  }
}

class _Api extends ApiClient {
  _Api() : super(Dio());
  String? lastPath;

  @override
  Future<Response<dynamic>> get(String path, {CancelToken? cancelToken}) async {
    lastPath = path;
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {
        'fromDate': '2026-07-13',
        'toDate': '2026-07-13',
        'timezone': 'Asia/Kolkata',
        'days': [
          {
            'date': '2026-07-13',
            'startUtc': '2026-07-12T18:30:00Z',
            'endUtc': '2026-07-13T18:30:00Z',
            'mealCount': 2,
            'calories': 1800,
            'targetCalories': 2200,
            'adherencePercent': 81.8,
          }
        ],
      },
    );
  }
}

void main() {
  final day = MealActivityDay(
    date: DateTime(2026, 7, 13),
    startUtc: DateTime.utc(2026, 7, 12, 18, 30),
    endUtc: DateTime.utc(2026, 7, 13, 18, 30),
    mealCount: 3,
    calories: 2050,
    targetCalories: 2200,
    adherencePercent: 93.2,
  );
  final activity = MealActivity(
    fromDate: DateTime(2026, 7, 7),
    toDate: DateTime(2026, 7, 13),
    timezone: 'Asia/Kolkata',
    days: [day],
  );

  test('activity repository parses timezone-aware day boundaries', () async {
    final api = _Api();
    final result = await MealHistoryRepository(api)
        .getActivity(DateTime(2026, 7, 13), DateTime(2026, 7, 13));

    expect(result, isA<Success<MealActivity>>());
    final value = (result as Success<MealActivity>).value;
    expect(value.days.single.startUtc, DateTime.utc(2026, 7, 12, 18, 30));
    expect(value.days.single.mealCount, 2);
    expect(api.lastPath, contains('/api/meals/activity?'));
    expect(api.lastPath, contains('fromDate=2026-07-13'));
  });

  testWidgets('history switches activity metric and filters a selected day',
      (tester) async {
    final repository = _HistoryRepository(activity);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        mealHistoryRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const HistoryPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('12-month activity'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Timezone: Asia/Kolkata'), 120,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Timezone: Asia/Kolkata'), findsOneWidget);
    await tester.tap(find.text('Target'));
    await tester.pumpAndSettle();
    expect(find.text('Darker days are closer to the calorie target.'),
        findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('3 meals')));
    await tester.pumpAndSettle();
    expect(repository.rangeCalls, 1);
    expect(find.textContaining('93% of target'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
