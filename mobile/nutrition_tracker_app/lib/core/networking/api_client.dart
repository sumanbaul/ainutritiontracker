import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

import '../../app/config/app_config.dart';
import '../../features/development_setup/domain/development_identity_service.dart';
import '../../features/auth/data/auth_service.dart';
import '../logging/app_logger.dart';
import '../storage/secure_storage_service.dart';

final developmentIdentityProvider = Provider<IDevelopmentIdentityService>(
    (ref) => DevelopmentIdentityService(
        ref.watch(appConfigProvider), ref.watch(secureStorageProvider)));
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final logger = ref.watch(appLoggerProvider);
  final identity = ref.watch(developmentIdentityProvider);
  final auth = ref.watch(authServiceProvider);
  final dio = Dio(BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.timeout,
      sendTimeout: config.timeout,
      receiveTimeout: config.timeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
    options.headers['X-Correlation-Id'] = const Uuid().v4();
    String? userId;
    try {
      userId = await identity.currentUserId();
    } catch (error) {
      logger.info('Development identity storage was unavailable: $error');
    }
    if (identity.isEnabled && userId != null && userId.isNotEmpty) {
      options.headers['X-Development-User-Id'] = userId;
    } else {
      final token = await auth.accessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    logger.info('${options.method} ${options.uri.path}');
    handler.next(options);
  }, onError: (error, handler) async {
    logger.info(
        'HTTP ${error.response?.statusCode ?? 'network'} ${error.requestOptions.uri.path}');
    if (error.response?.statusCode == 401 &&
        error.requestOptions.extra['retriedAfterRefresh'] != true &&
        !error.requestOptions.path.startsWith('/api/auth/')) {
      final token = await auth.refresh();
      if (token != null) {
        final request = error.requestOptions;
        request.extra['retriedAfterRefresh'] = true;
        request.headers['Authorization'] = 'Bearer $token';
        try {
          return handler.resolve(await dio.fetch<dynamic>(request));
        } catch (_) {}
      }
    }
    handler.next(error);
  }));
  return dio;
});

class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;
  Future<Response<dynamic>> get(String path, {CancelToken? cancelToken}) =>
      _dio.get(path, cancelToken: cancelToken);
  Future<Response<String>> getPlain(String path, {CancelToken? cancelToken}) =>
      _dio.get<String>(path,
          cancelToken: cancelToken,
          options: Options(responseType: ResponseType.plain));
  Future<Response<Uint8List>> getBytes(String path,
          {CancelToken? cancelToken}) =>
      _dio.get<Uint8List>(path,
          cancelToken: cancelToken,
          options: Options(responseType: ResponseType.bytes));
  Future<Response<dynamic>> post(String path, {Object? data}) =>
      _dio.post(path, data: data);
  Future<Response<dynamic>> postMultipart(String path, FormData data,
          {CancelToken? cancelToken, ProgressCallback? onSendProgress}) =>
      _dio.post(path,
          data: data,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          options: Options(contentType: Headers.multipartFormDataContentType));
  Future<Response<dynamic>> put(String path, {Object? data}) =>
      _dio.put(path, data: data);
  Future<Response<dynamic>> delete(String path) => _dio.delete(path);
}

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
