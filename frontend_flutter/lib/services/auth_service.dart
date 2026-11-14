import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/usuario.dart';
import 'storage_service.dart';

class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthService({
    ApiClient? apiClient,
    StorageService? storageService,
  })  : _storageService = storageService ?? StorageService(),
        _apiClient = apiClient ??
            ApiClient(
              storageService: storageService ?? StorageService(),
            );

  StorageService get storageService => _storageService;

  /// Inicia sesión enviando credenciales a 'POST /api/auth/login'.
  /// Si es exitoso, almacena el token en SecureStorage y los datos no sensibles en SharedPreferences.
  /// NUNCA imprime contraseñas ni tokens en consola.
  Future<Usuario> login(String email, String password) async {
    final payload = {
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    final response = await _apiClient.post(
      ApiConstants.loginEndpoint,
      data: payload,
    );

    if (response is Map<String, dynamic>) {
      final token = response['access_token'] as String?;
      final userData = response['user'] as Map<String, dynamic>?;

      if (token == null || token.isEmpty || userData == null) {
        throw Exception('Respuesta de autenticación incompleta del servidor.');
      }

      final usuario = Usuario.fromJson(userData);

      // 1. Guardar access_token en almacenamiento seguro cifrado
      await _storageService.saveToken(token);

      // 2. Guardar datos informativos no sensibles en SharedPreferences
      await _storageService.saveUserData(
        id: usuario.id,
        name: usuario.nombre,
        email: usuario.email,
      );

      return usuario;
    } else {
      throw Exception('Formato de respuesta inválido al iniciar sesión.');
    }
  }

  /// Consulta la información del usuario autenticado en 'GET /api/auth/me'.
  /// Permite verificar si el token sigue vigente en el servidor.
  Future<Usuario> getPerfil() async {
    final response = await _apiClient.get(ApiConstants.meEndpoint);

    if (response is Map<String, dynamic>) {
      final usuario = Usuario.fromJson(response);

      // Actualizar datos locales informativos
      await _storageService.saveUserData(
        id: usuario.id,
        name: usuario.nombre,
        email: usuario.email,
      );

      return usuario;
    } else {
      throw Exception('Formato de respuesta inválido al consultar perfil.');
    }
  }

  /// Cierra la sesión eliminando el token de SecureStorage y los datos locales de SharedPreferences.
  Future<void> logout() async {
    await _storageService.clearAll();
  }
}

