import 'package:flutter/foundation.dart';
import '../core/errors/api_exception.dart';
import '../core/network/auth_interceptor.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  Usuario? _usuarioActual;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  /// Factory constructor que garantiza que AuthController y AuthService
  /// compartan la misma instancia de StorageService.
  factory AuthController({
    AuthService? authService,
    StorageService? storageService,
    bool initialAuthenticated = false,
    Usuario? initialUsuario,
  }) {
    final sharedStorage = storageService ?? (authService?.storageService ?? StorageService());
    final resolvedAuthService = authService ?? AuthService(storageService: sharedStorage);

    return AuthController._(
      authService: resolvedAuthService,
      storageService: sharedStorage,
      initialAuthenticated: initialAuthenticated,
      initialUsuario: initialUsuario,
    );
  }

  AuthController._({
    required this._authService,
    required this._storageService,
    bool initialAuthenticated = false,
    Usuario? initialUsuario,
  })  : _isAuthenticated = initialAuthenticated,
        _usuarioActual = initialUsuario,
        _isInitialized = initialAuthenticated {
    // Escucha global de respuestas HTTP 401 en peticiones protegidas
    AuthInterceptor.globalSessionExpiredHandler = _handleSessionExpired;
  }

  // Getters reactivos
  Usuario? get usuarioActual => _usuarioActual;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  String? get nombreUsuario => _usuarioActual?.nombre;
  String? get emailUsuario => _usuarioActual?.email;
  StorageService get storageService => _storageService;

  // ============================================================================
  // VERIFICACIÓN INICIAL DE SESIÓN (PERSISTENCIA)
  // ============================================================================

  /// Verifica en el arranque si existe un token en SecureStorage y si sigue vigente
  /// consultando el perfil del usuario en el backend (/api/auth/me).
  Future<void> verificarSesionInicial() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasToken = await _storageService.hasToken();
      if (!hasToken) {
        debugPrint('[AUTH CONTROLLER] No se detectó token almacenado en arranque.');
        _isAuthenticated = false;
        _usuarioActual = null;
        return;
      }

      debugPrint('[AUTH CONTROLLER] Token detectado en almacenamiento seguro. Validando vigencia con el servidor...');

      // Validar vigencia del token contra el backend (/api/auth/me)
      final usuario = await _authService.getPerfil();
      _usuarioActual = usuario;
      _isAuthenticated = true;
      _errorMessage = null;
      debugPrint('[AUTH CONTROLLER] Sesión validada exitosamente por el servidor para: ${usuario.email}');
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // HTTP 401: Token inválido o expirado confirmado por el servidor -> limpiar credenciales
        debugPrint('[AUTH CONTROLLER] Token inválido o expirado (HTTP 401). Limpiando sesión...');
        await _storageService.clearAll();
        _isAuthenticated = false;
        _usuarioActual = null;
        _errorMessage = 'Su sesión ha expirado o el token es inválido. Por favor, inicie sesión nuevamente.';
      } else {
        // Error de conexión, timeout o servidor no disponible:
        // Conservar el token y los datos almacenados; NO destruir la sesión.
        // No se declara una sesión validada por el servidor únicamente por existir datos en SharedPreferences.
        debugPrint('[AUTH CONTROLLER] Error de red o servidor al verificar sesión (${e.statusCode}): ${e.message}. Se conserva el token almacenado.');
        _isAuthenticated = false;
        _usuarioActual = null;
        _errorMessage = e.message;
      }
    } catch (e, stackTrace) {
      debugPrint('[AUTH CONTROLLER] Error inesperado al verificar sesión inicial: $e\nStackTrace: $stackTrace');
      // Ante excepciones imprevistas no HTTP, se conserva el token y no se destruye la sesión
      _isAuthenticated = false;
      _usuarioActual = null;
      _errorMessage = 'No fue posible validar la sesión con el servidor.';
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ============================================================================
  // INICIO DE SESIÓN
  // ============================================================================

  /// Inicia sesión con correo y contraseña.
  /// Retorna true si es exitoso, false si las credenciales fallan o hay error de red.
  Future<bool> iniciarSesion(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final usuario = await _authService.login(email, password);
      _usuarioActual = usuario;
      _isAuthenticated = true;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      _usuarioActual = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error de comunicación con el servidor: $e';
      _isAuthenticated = false;
      _usuarioActual = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // CIERRE DE SESIÓN
  // ============================================================================

  /// Cierra la sesión, limpia SecureStorage y SharedPreferences, y notifica a GoRouter.
  Future<void> cerrarSesion() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('[AUTH CONTROLLER] Error al cerrar sesión: $e');
    } finally {
      _usuarioActual = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // GESTIÓN DE EXPIRACIÓN Y ERRORES
  // ============================================================================

  void _handleSessionExpired() {
    if (_isAuthenticated) {
      _isAuthenticated = false;
      _usuarioActual = null;
      _errorMessage = 'Su sesión ha expirado. Por favor, ingrese sus credenciales nuevamente.';
      notifyListeners();
    }
  }

  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (AuthInterceptor.globalSessionExpiredHandler == _handleSessionExpired) {
      AuthInterceptor.globalSessionExpiredHandler = null;
    }
    super.dispose();
  }
}
