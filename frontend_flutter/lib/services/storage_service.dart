import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'jwt_access_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyIsAuthenticated = 'is_authenticated';

  /// Configuración compatible y estable para Android en flutter_secure_storage 9.x:
  /// - encryptedSharedPreferences: false (utiliza cifrado estándar RSA/AES respaldado por
  ///   Android Keystore, evitando las fallas conocidas de la librería AndroidX Security Crypto
  ///   y pérdida de llaves tras finalizar el proceso de la aplicación en emuladores y dispositivos).
  /// - resetOnError: false (mantenido en false para evitar el borrado automático e irreversible
  ///   de los datos ante errores transitorios del almacén seguro).
  static const AndroidOptions _defaultAndroidOptions = AndroidOptions(
    encryptedSharedPreferences: false,
    resetOnError: false,
  );

  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  StorageService({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? prefs,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: _defaultAndroidOptions,
            ) {
    _prefs = prefs;
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============================================================================
  // 1. MANEJO EXCLUSIVO DEL JWT EN FLUTTER_SECURE_STORAGE
  // ============================================================================

  /// Almacena el token de acceso de forma cifrada en el contenedor seguro del sistema.
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _keyToken, value: token);
      debugPrint('[STORAGE] Token JWT guardado exitosamente en almacenamiento seguro.');
    } catch (e, stackTrace) {
      debugPrint('[STORAGE ERROR] Error crítico al guardar access_token en secure storage: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Recupera el token de acceso cifrado. Retorna null si no existe o si ocurre un error.
  Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: _keyToken);
      if (token != null && token.trim().isNotEmpty) {
        debugPrint('[STORAGE] Token JWT recuperado exitosamente de almacenamiento seguro.');
        return token;
      }
      debugPrint('[STORAGE] No se encontró ningún token almacenado en secure storage.');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[STORAGE ERROR] Error al leer access_token de secure storage: $e\nStackTrace: $stackTrace');
      return null;
    }
  }

  /// Comprueba la existencia del token almacenado de forma rápida.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }

  /// Elimina el token de acceso del contenedor seguro.
  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: _keyToken);
      debugPrint('[STORAGE] Token JWT eliminado de almacenamiento seguro.');
    } catch (e, stackTrace) {
      debugPrint('[STORAGE ERROR] Error al eliminar access_token de secure storage: $e\nStackTrace: $stackTrace');
    }
  }

  // ============================================================================
  // 2. MANEJO DE DATOS NO SENSIBLES EN SHARED_PREFERENCES
  // ============================================================================

  /// Almacena información informativa del usuario (nombre, correo, ID).
  /// NUNCA almacena contraseñas ni tokens en shared_preferences.
  Future<void> saveUserData({
    required int id,
    required String name,
    required String email,
  }) async {
    final p = await _getPrefs();
    await p.setInt(_keyUserId, id);
    await p.setString(_keyUserName, name);
    await p.setString(_keyUserEmail, email);
    await p.setBool(_keyIsAuthenticated, true);
  }

  /// Retorna el nombre del usuario almacenado.
  Future<String?> getUserName() async {
    final p = await _getPrefs();
    return p.getString(_keyUserName);
  }

  /// Retorna el correo del usuario almacenado.
  Future<String?> getUserEmail() async {
    final p = await _getPrefs();
    return p.getString(_keyUserEmail);
  }

  /// Retorna el ID del usuario.
  Future<int?> getUserId() async {
    final p = await _getPrefs();
    return p.getInt(_keyUserId);
  }

  /// Consulta si la bandera local de sesión activa está encendida.
  Future<bool> isAuthenticated() async {
    final p = await _getPrefs();
    return p.getBool(_keyIsAuthenticated) ?? false;
  }

  /// Retorna un mapa con los datos locales del usuario si existen en SharedPreferences.
  Future<Map<String, dynamic>?> getUserData() async {
    final p = await _getPrefs();
    final id = p.getInt(_keyUserId);
    final name = p.getString(_keyUserName);
    final email = p.getString(_keyUserEmail);
    if (id != null && name != null && email != null) {
      return {
        'id': id,
        'nombre': name,
        'email': email,
      };
    }
    return null;
  }

  /// Limpia los datos de usuario en SharedPreferences.
  Future<void> clearUserData() async {
    final p = await _getPrefs();
    await p.remove(_keyUserId);
    await p.remove(_keyUserName);
    await p.remove(_keyUserEmail);
    await p.setBool(_keyIsAuthenticated, false);
  }

  /// Elimina de forma integral todos los datos de sesión (token seguro + datos no sensibles).
  Future<void> clearAll() async {
    await deleteToken();
    await clearUserData();
  }
}
