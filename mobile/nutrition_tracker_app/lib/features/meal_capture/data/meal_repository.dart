import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../domain/meal_review.dart';

final mealRepositoryProvider =
    Provider((ref) => MealRepository(ref.watch(apiClientProvider)));

class MealRepository {
  MealRepository(this._api);
  final ApiClient _api;
  Future<Result<MealReview>> analyse(File image,
      {required DateTime consumedAtUtc,
      required String? cuisineHint,
      required bool mockMode,
      required String? mockScenario,
      String? providerId,
      String? modelId,
      CancelToken? cancelToken,
      ProgressCallback? onProgress}) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path,
            filename: image.path.split(Platform.pathSeparator).last),
        'consumedAtUtc': consumedAtUtc.toIso8601String(),
        'locale': 'en-IN',
        if (cuisineHint != null && cuisineHint.trim().isNotEmpty)
          'cuisineHints': cuisineHint.trim(),
        if (mockMode && mockScenario != null) 'mockScenario': mockScenario,
        if (providerId != null) 'providerId': providerId,
        if (modelId != null) 'modelId': modelId
      });
      final r = await _api.postMultipart(ApiEndpoints.mealAnalysis, form,
          cancelToken: cancelToken, onSendProgress: onProgress);
      return Success(
          MealReview.fromJson(Map<String, dynamic>.from(r.data as Map)));
    } on DioException catch (e) {
      return Failure(_failure(e));
    }
  }

  Future<Result<MealReview>> review(String mealId) async =>
      _reviewRequest(() => _api.get(ApiEndpoints.mealReview(mealId)));
  Future<Result<MealReview>> createManual(
          {required String name,
          required List<Map<String, dynamic>> items}) async =>
      _reviewRequest(() => _api.post(ApiEndpoints.manualMeal, data: {
            'name': name,
            'mealType': 'Unknown',
            'consumedAtUtc': DateTime.now().toUtc().toIso8601String(),
            'items': items
          }));
  Future<Result<MealReview>> updateItem(String mealId, MealReviewItem item,
          {required double grams,
          required String preparationMethod,
          String? foodId}) async =>
      _reviewRequest(
          () => _api.put(ApiEndpoints.mealItem(mealId, item.id), data: {
                'foodId': foodId,
                'grams': grams,
                'servingQuantity': null,
                'servingUnitCode': null,
                'preparationMethod': preparationMethod
              }));
  Future<Result<MealReview>> removeItem(String mealId, String itemId) async =>
      _reviewRequest(() => _api.delete(ApiEndpoints.mealItem(mealId, itemId)));
  Future<Result<MealReview>> addItem(String mealId,
          {required String foodId,
          required double grams,
          required String preparationMethod}) async =>
      _reviewRequest(() => _api.post(ApiEndpoints.mealItems(mealId), data: {
            'foodId': foodId,
            'grams': grams,
            'servingQuantity': null,
            'servingUnitCode': null,
            'preparationMethod': preparationMethod
          }));
  Future<Result<MealReview>> confirm(String mealId) async =>
      _reviewRequest(() => _api.post(ApiEndpoints.mealConfirm(mealId)));
  Future<Result<List<MealCorrection>>> corrections(String mealId) async {
    try {
      final r = await _api.get(ApiEndpoints.mealCorrections(mealId));
      return Success((r.data as List)
          .map((x) =>
              MealCorrection.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList());
    } on DioException catch (e) {
      return Failure(_failure(e));
    }
  }

  Future<Result<List<FoodSearchItem>>> searchFoods(String query) async {
    try {
      final r = await _api.get(
          '${ApiEndpoints.foodsSearch}?q=${Uri.encodeQueryComponent(query)}');
      return Success((r.data as List)
          .map((x) =>
              FoodSearchItem.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList());
    } on DioException catch (e) {
      return Failure(_failure(e));
    }
  }

  Future<Result<MealReview>> _reviewRequest(
      Future<Response<dynamic>> Function() request) async {
    try {
      final r = await request();
      return Success(
          MealReview.fromJson(Map<String, dynamic>.from(r.data as Map)));
    } on DioException catch (e) {
      return Failure(_failure(e));
    }
  }

  AppFailure _failure(DioException e) {
    final status = e.response?.statusCode;
    final message = switch (status) {
      400 => 'Check the meal details and try again.',
      401 => 'Development identity is required.',
      413 => 'The image is larger than 5 MB.',
      415 => 'Use a JPEG, PNG, or WebP image.',
      502 => 'The meal-analysis provider returned an unusable response.',
      504 => 'Meal analysis timed out. Try again.',
      _ => 'Meal request failed. Check the connection and retry.'
    };
    return AppFailure(message, statusCode: status, details: e.message);
  }
}
