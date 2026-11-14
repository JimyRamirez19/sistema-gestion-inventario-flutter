import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/storage_service.dart';

/// Interceptor de Dio para autenticación JWT.
/// 
/// 1. Inyecta automáticamente `Authorization: Bearer <token>` a todas las peticiones
///    que cuenten con un token guardado en StorageService.
/// 2. Captura respuestas HTTP 401 (token expirado o inválido) en peticiones protegidas,
///    limpia la sesión local y notifica mediante un callback para redirigir al login.
class AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final VoidCallback? onSessionExpired;

  /// Callback global opcional que puede registrar el AuthController
  static VoidCallback? globalSessionExpiredHandler;

  AuthInterceptor({
    StorageService? storageService,
    this.onSessionExpired,
  }) : _storageService = storageService ?? StorageService();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Si la petición es el endpoint de login, no requiere adjuntar token existente
    final isLoginRequest = options.path.contains('/auth/login');
    if (!isLoginRequest) {
      try {
        final token = await _storageService.getToken();
        if (token != null && token.trim().isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        debugPrint('[AUTH INTERCEPTOR] Error al recuperar token para la petición: $e');
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    // Si el error 401 proviene de un intento de login con credenciales erróneas,
    // se deja fluir el error normal para que la pantalla muestre 'Credenciales incorrectas'.
    final isLoginAttempt = path.contains('/auth/login');

    if (statusCode == 401 && !isLoginAttempt) {
      debugPrint('[AUTH INTERCEPTOR] HTTP 401 detectado en $path. La sesión ha expirado o el token es inválido.');

      try {
        // Limpieza controlada de almacenamiento
        await _storageService.clearAll();
      } catch (e) {
        debugPrint('[AUTH INTERCEPTOR] Error al limpiar almacenamiento tras 401: $e');
      }

      // Notificación al callback de sesión expirada
      onSessionExpired?.call();
      globalSessionExpiredHandler?.call();
    }

    return handler.next(err);
  }
}
