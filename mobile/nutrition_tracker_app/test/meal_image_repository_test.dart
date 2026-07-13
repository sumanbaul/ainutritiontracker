import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/core/networking/api_client.dart';
import 'package:nutrition_tracker_app/features/meal_capture/data/meal_image_repository.dart';

class _ApiClient extends ApiClient {
  _ApiClient() : super(Dio());
  final calls = <String, int>{};

  @override
  Future<Response<Uint8List>> getBytes(String path,
      {CancelToken? cancelToken}) async {
    calls[path] = (calls[path] ?? 0) + 1;
    return Response(
        requestOptions: RequestOptions(path: path),
        data: Uint8List.fromList(path.codeUnits));
  }
}

void main() {
  test('meal image repository keeps a bounded least-recently-used cache',
      () async {
    final api = _ApiClient();
    final repository = MealImageRepository(api, capacity: 2);

    await repository.get('one');
    await repository.get('two');
    await repository.get('one');
    await repository.get('three');
    await repository.get('two');

    expect(api.calls['/api/meals/one/image'], 1);
    expect(api.calls['/api/meals/two/image'], 2);
  });
}
