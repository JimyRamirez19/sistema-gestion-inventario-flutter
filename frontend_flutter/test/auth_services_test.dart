import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_flutter/core/network/auth_interceptor.dart';
import 'package:frontend_flutter/models/usuario.dart';
import 'package:frontend_flutter/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas Unitarias de Autenticación y Almacenamiento (Sub-paso 3.2)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('1. Modelo Usuario: serialización y deserialización correcta', () {
      final json = {
        'id': 1,
        'nombre': 'Administrador del Sistema',
        'email': 'admin@inventario.com',
        'is_active': true,
      };

      final usuario = Usuario.fromJson(json);
      expect(usuario.id, 1);
      expect(usuario.nombre, 'Administrador del Sistema');
      expect(usuario.email, 'admin@inventario.com');
      expect(usuario.isActive, true);

      final outJson = usuario.toJson();
      expect(outJson['email'], 'admin@inventario.com');
      expect(outJson['is_active'], true);
    });

    test('2. StorageService: guardar y recuperar en secure storage y shared preferences', () async {
      final storage = StorageService();

      // Verificar estado inicial
      expect(await storage.hasToken(), false);
      expect(await storage.getToken(), isNull);
      expect(await storage.isAuthenticated(), false);

      // Guardar token y datos
      await storage.saveToken('jwt.sample.token.123');
      await storage.saveUserData(
        id: 1,
        name: 'Administrador',
        email: 'admin@inventario.com',
      );

      // Verificar persistencia
      expect(await storage.hasToken(), true);
      expect(await storage.getToken(), 'jwt.sample.token.123');
      expect(await storage.isAuthenticated(), true);
      expect(await storage.getUserId(), 1);
      expect(await storage.getUserName(), 'Administrador');
      expect(await storage.getUserEmail(), 'admin@inventario.com');

      // Limpiar todo (logout)
      await storage.clearAll();
      expect(await storage.hasToken(), false);
      expect(await storage.getToken(), isNull);
      expect(await storage.isAuthenticated(), false);
      expect(await storage.getUserName(), isNull);
    });

    test('3. AuthInterceptor: inyecta Authorization: Bearer <token> en petición protegida', () async {
      final storage = StorageService();
      await storage.saveToken('token_de_prueba_jwt');

      final interceptor = AuthInterceptor(storageService: storage);
      final options = RequestOptions(path: '/productos');

      // Crear handler falso para probar onRequest
      var nextCalled = false;
      
      // Probar llamando a onRequest directamente sin lanzar excepciones
      final fakeHandler = _TestRequestHandler((opts) {
        nextCalled = true;
      });

      await interceptor.onRequest(options, fakeHandler);

      expect(nextCalled, true);
      expect(options.headers['Authorization'], 'Bearer token_de_prueba_jwt');
    });

    test('4. AuthInterceptor: no inyecta Authorization en /auth/login', () async {
      final storage = StorageService();
      await storage.saveToken('token_de_prueba_jwt');

      final interceptor = AuthInterceptor(storageService: storage);
      final options = RequestOptions(path: '/auth/login');

      var nextCalled = false;
      final fakeHandler = _TestRequestHandler((opts) {
        nextCalled = true;
      });

      await interceptor.onRequest(options, fakeHandler);

      expect(nextCalled, true);
      expect(options.headers.containsKey('Authorization'), false);
    });

    test('5. AuthInterceptor: captura HTTP 401 en /productos, limpia almacenamiento y activa callback', () async {
      final storage = StorageService();
      await storage.saveToken('token_expirado');
      await storage.saveUserData(id: 1, name: 'Admin', email: 'admin@test.com');
      expect(await storage.hasToken(), true);

      bool sessionExpiredCalled = false;
      final interceptor = AuthInterceptor(
        storageService: storage,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );

      final dioError = DioException(
        requestOptions: RequestOptions(path: '/productos'),
        response: Response(
          requestOptions: RequestOptions(path: '/productos'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      var nextErrorCalled = false;
      final fakeErrorHandler = _TestErrorHandler((err) {
        nextErrorCalled = true;
      });

      await interceptor.onError(dioError, fakeErrorHandler);

      expect(sessionExpiredCalled, true);
      expect(nextErrorCalled, true);
      expect(await storage.hasToken(), false);
      expect(await storage.isAuthenticated(), false);
    });

    test('6. AuthInterceptor: HTTP 401 en /auth/login NO activa sessionExpired', () async {
      final storage = StorageService();
      bool sessionExpiredCalled = false;

      final interceptor = AuthInterceptor(
        storageService: storage,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );

      final loginError = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      var nextErrorCalled = false;
      final fakeErrorHandler = _TestErrorHandler((err) {
        nextErrorCalled = true;
      });

      await interceptor.onError(loginError, fakeErrorHandler);

      expect(sessionExpiredCalled, false);
      expect(nextErrorCalled, true);
    });
  });
}

class _TestRequestHandler extends RequestInterceptorHandler {
  final void Function(RequestOptions) onNext;
  _TestRequestHandler(this.onNext);

  @override
  void next(RequestOptions requestOptions) {
    onNext(requestOptions);
  }
}

class _TestErrorHandler extends ErrorInterceptorHandler {
  final void Function(DioException) onNext;
  _TestErrorHandler(this.onNext);

  @override
  void next(DioException err) {
    onNext(err);
  }
}
