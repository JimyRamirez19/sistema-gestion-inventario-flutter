import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../errors/api_exception.dart';

class ApiClient {
  late final Dio dio;

  ApiClient({String? baseUrlOverride}) {
    final base = baseUrlOverride ?? ApiConstants.baseUrl;
    dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: ApiConstants.connectTimeoutSeconds),
        receiveTimeout: const Duration(seconds: ApiConstants.receiveTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('[DIO REQUEST] ${options.method} -> ${options.uri}');
            if (options.data != null) {
              debugPrint('[DIO BODY] ${options.data}');
            }
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('[DIO RESPONSE] ${response.statusCode} <- ${response.requestOptions.uri}');
            return handler.next(response);
          },
          onError: (error, handler) {
            debugPrint('[DIO ERROR] ${error.response?.statusCode}: ${error.message} on ${error.requestOptions.uri}');
            return handler.next(error);
          },
        ),
      );
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
