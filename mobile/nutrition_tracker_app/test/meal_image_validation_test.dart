import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/features/meal_capture/domain/image_validation.dart';

void main() {
  test('accepts valid JPEG signature', () {
    expect(
        validateMealImage(
          path: 'meal.jpg',
          bytes: 1024,
          header: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]),
        ),
        isNull);
  });

  test('rejects oversized and mismatched image', () {
    expect(
        validateMealImage(
          path: 'meal.png',
          bytes: maxMealImageBytes + 1,
          header: Uint8List.fromList([0xff, 0xd8, 0xff]),
        ),
        contains('5 MB'));
    expect(
        validateMealImage(
          path: 'meal.png',
          bytes: 100,
          header: Uint8List.fromList([0xff, 0xd8, 0xff]),
        ),
        contains('valid'));
  });
}
