import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';

final mealImageRepositoryProvider =
    Provider((ref) => MealImageRepository(ref.watch(apiClientProvider)));

class MealImageRepository {
  MealImageRepository(this._api, {this.capacity = 16});
  final ApiClient _api;
  final int capacity;
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  Future<Uint8List?> get(String mealId) async {
    final cached = _cache.remove(mealId);
    if (cached != null) {
      _cache[mealId] = cached;
      return cached;
    }
    try {
      final response = await _api.getBytes(ApiEndpoints.mealImage(mealId));
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      _cache[mealId] = bytes;
      while (_cache.length > capacity) {
        _cache.remove(_cache.keys.first);
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  void evict(String mealId) => _cache.remove(mealId);
  void clear() => _cache.clear();
}
