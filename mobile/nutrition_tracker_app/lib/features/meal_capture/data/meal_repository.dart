import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../domain/meal_review.dart';
import '../../../core/sync/offline_sync_service.dart';
import 'package:uuid/uuid.dart';

final mealRepositoryProvider = Provider((ref) => MealRepository(
    ref.watch(apiClientProvider),
    ref.watch(offlineSyncProvider),
    () => currentUserScope(ref)));

class MealRepository {
  MealRepository(this._api, [this._sync, this._userScope]);
  final ApiClient _api;
  final OfflineSyncService? _sync;
  final Future<String?> Function()? _userScope;
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
      {required String name, required List<Map<String, dynamic>> items}) async {
    final id = const Uuid().v4();
    final payload = {
      'name': name,
      'mealType': 'Unknown',
      'consumedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'items': items
    };
    try {
      final response = await _api.post(ApiEndpoints.manualMeal, data: payload);
      return Success(
          MealReview.fromJson(Map<String, dynamic>.from(response.data as Map)));
    } on DioException catch (error) {
      final user = await _userScope?.call();
      if (error.response == null && user != null && _sync != null) {
        await _sync.enqueue(
            userId: user,
            operation: 'create',
            entityType: 'manual-meal',
            entityId: id,
            payload: {
              '_path': ApiEndpoints.manualMeal,
              '_method': 'POST',
              ...payload
            });
        return const Failure(AppFailure(
            'Manual draft saved offline and will sync after reconnecting.'));
      }
      return Failure(_failure(error));
    }
  }

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
  Future<Result<FoodResolutionResult>> resolveFood(String mealId, String itemId,
      {required String query,
      String mode = 'CatalogMatch',
      String? providerId,
      String? modelId}) async {
    try {
      final response = await _api
          .post(ApiEndpoints.mealItemResolution(mealId, itemId), data: {
        'query': query,
        'mode': mode,
        if (providerId != null) 'providerId': providerId,
        if (modelId != null) 'modelId': modelId
      });
      return Success(FoodResolutionResult.fromJson(
          Map<String, dynamic>.from(response.data as Map)));
    } on DioException catch (error) {
      return Failure(_failure(error));
    }
  }

  Future<Result<MealReview>> confirmEstimatedFood(String mealId, String itemId,
          {required AiFoodEstimate estimate,
          required CustomFoodDraft reviewed,
          required double grams,
          required String preparationMethod}) async =>
      _reviewRequest(() => _api.post(
              ApiEndpoints.mealItemEstimateConfirmation(mealId, itemId),
              data: {
                'estimateToken': estimate.token,
                'name': reviewed.name,
                'description':
                    reviewed.description.isEmpty ? null : reviewed.description,
                'category': estimate.category,
                'cuisine': estimate.cuisine,
                'preparationMethod': preparationMethod,
                'foodState': estimate.foodState,
                'nutritionPer100Grams': {
                  'calories': reviewed.calories,
                  'protein': reviewed.protein,
                  'carbohydrates': reviewed.carbs,
                  'fat': reviewed.fat,
                  'fibre': reviewed.fibre
                },
                'grams': grams
              }));

  Future<Result<String>> createCustomFood(CustomFoodDraft draft) async {
    try {
      final response = await _api.post(ApiEndpoints.customFoods, data: {
        'displayName': draft.name,
        'canonicalName': draft.name,
        'description': draft.description.isEmpty ? null : draft.description,
        'category': 'PreparedDish',
        'cuisine': 'General',
        'preparationMethod': 'Unknown',
        'foodState': 'Prepared',
        'nutritionPer100Grams': {
          'calories': draft.calories,
          'protein': draft.protein,
          'carbohydrates': draft.carbs,
          'fat': draft.fat,
          'fibre': draft.fibre
        },
        'aliases': <String>[]
      });
      return Success((response.data as Map)['id'] as String);
    } on DioException catch (error) {
      return Failure(_failure(error));
    }
  }

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
      503 => 'The AI resolver is not configured or temporarily unavailable.',
      429 => 'The AI resolver is temporarily rate limited. Try again shortly.',
      504 => 'Meal analysis timed out. Try again.',
      _ => 'Meal request failed. Check the connection and retry.'
    };
    return AppFailure(message, statusCode: status, details: e.message);
  }
}
