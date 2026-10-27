import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Tiempo de espera agotado al conectar con el servidor. Verifique que el backend esté ejecutándose.',
          statusCode: 408,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No fue posible establecer conexión con el backend. Compruebe la URL en .env y que el servidor uvicorn esté activo.',
          statusCode: 503,
        );
      case DioExceptionType.badResponse:
        final status = dioException.response?.statusCode;
        final data = dioException.response?.data;

        String errorDetail = 'Error al procesar la solicitud ($status).';
        if (data is Map<String, dynamic>) {
          if (data['detail'] is String) {
            errorDetail = data['detail'];
          } else if (data['errores'] is List) {
            errorDetail = (data['errores'] as List).join('\n');
          } else if (data['message'] is String) {
            errorDetail = data['message'];
          }
        }

        return ApiException(
          message: errorDetail,
          statusCode: status,
          details: data,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'La solicitud al servidor fue cancelada.',
        );
      default:
        return ApiException(
          message: 'Ocurrió un error inesperado de comunicación: ${dioException.message ?? 'Desconocido'}',
        );
    }
  }

  @override
  String toString() => message;
}
