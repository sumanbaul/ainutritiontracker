import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/app/theme/app_theme.dart';
import 'package:nutrition_tracker_app/core/networking/api_client.dart';
import 'package:nutrition_tracker_app/core/result/result.dart';
import 'package:nutrition_tracker_app/features/meal_capture/data/meal_image_repository.dart';
import 'package:nutrition_tracker_app/features/meal_capture/data/meal_repository.dart';
import 'package:nutrition_tracker_app/features/meal_capture/domain/meal_review.dart';
import 'package:nutrition_tracker_app/features/meal_capture/presentation/meal_photo.dart';
import 'package:nutrition_tracker_app/features/meal_capture/presentation/meal_review_page.dart';

class _ImageRepository extends MealImageRepository {
  _ImageRepository() : super(ApiClient(Dio()));

  @override
  Future<Uint8List?> get(String mealId) async => base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=');
}

class _MealRepository extends MealRepository {
  _MealRepository(this.meal) : super(ApiClient(Dio()));
  final MealReview meal;

  @override
  Future<Result<MealReview>> review(String mealId) async => Success(meal);
}

void main() {
  test('filled action colors remain contrasting in light and dark themes', () {
    final light =
        AppTheme.light().filledButtonTheme.style!.foregroundColor!.resolve({});
    final dark =
        AppTheme.dark().filledButtonTheme.style!.foregroundColor!.resolve({});
    final lightBackground =
        AppTheme.light().filledButtonTheme.style!.backgroundColor!.resolve({});
    final darkBackground =
        AppTheme.dark().filledButtonTheme.style!.backgroundColor!.resolve({});

    expect(light, isNot(lightBackground));
    expect(dark, isNot(darkBackground));
    expect(dark, AppColors.ink);
  });

  testWidgets('meal photo expands and uses full-bleed cover', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        mealImageRepositoryProvider.overrideWithValue(_ImageRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Center(
          child: SizedBox(
            width: 240,
            height: 120,
            child: MealPhoto(mealId: 'meal', hasImage: true),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
    expect(image.width, double.infinity);
    expect(image.height, double.infinity);
    expect(tester.getSize(find.byType(MealPhoto)), const Size(240, 120));
    expect(tester.takeException(), isNull);
  });

  testWidgets('review sheet stays below its app bar at narrow large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final items = List.generate(
      8,
      (index) => MealReviewItem(
        id: 'item-$index',
        detectedName: 'Detected food $index',
        foodId: null,
        grams: 100,
        servingUnit: 'gram',
        calories: 100,
        protein: 4,
        carbs: 12,
        fat: 3,
        fibre: 2,
        recognitionConfidence: .9,
        nutritionMatchConfidence: .8,
        nutritionMatchState: 'UserSelected',
        preparationMethod: 'Unknown',
        requiresConfirmation: true,
        warnings: const [],
      ),
    );
    final meal = MealReview(
      mealId: 'meal',
      name: 'Test meal',
      status: 'AwaitingReview',
      totalCalories: 800,
      totalProtein: 32,
      totalCarbs: 96,
      totalFat: 24,
      totalFibre: 16,
      hasIncompleteNutrition: false,
      items: items,
      warnings: const [],
      provider: 'OpenAi',
      model: 'test-model',
      hasImage: false,
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        mealRepositoryProvider.overrideWithValue(_MealRepository(meal)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const MediaQuery(
          data: MediaQueryData(
              size: Size(320, 760), textScaler: TextScaler.linear(1.3)),
          child: MealReviewPage(mealId: 'meal'),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Confirm meal'), findsOneWidget);
    expect(find.text('Food details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
