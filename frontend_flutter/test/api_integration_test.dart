import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_flutter/core/network/api_client.dart';
import 'package:frontend_flutter/services/auth_service.dart';
import 'package:frontend_flutter/services/producto_service.dart';
import 'package:frontend_flutter/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProductoService service;
  late StorageService storageService;

  setUpAll(() async {
    // Permitir tráfico de red HTTP real en pruebas de integración
    HttpOverrides.global = null;

    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    // Cargar configuración de entorno para pruebas dinámicamente sin quemar credenciales en el código
    final backendEnvFile = File('../backend/.env');
    if (backendEnvFile.existsSync()) {
      final envContent = backendEnvFile.readAsStringSync();
      dotenv.loadFromString(
        envString: '$envContent\nAPI_BASE_URL=http://127.0.0.1:8000/api',
      );
    } else {
      dotenv.loadFromString(envString: 'API_BASE_URL=http://127.0.0.1:8000/api');
    }

    final testEmail = dotenv.env['SEED_ADMIN_EMAIL'] ??
        Platform.environment['SEED_ADMIN_EMAIL'] ??
        'admin@inventario.com';
    final testPassword = dotenv.env['SEED_ADMIN_PASSWORD'] ??
        Platform.environment['SEED_ADMIN_PASSWORD'] ??
        '';

    storageService = StorageService();
    final apiClient = ApiClient(
      baseUrlOverride: 'http://127.0.0.1:8000/api',
      storageService: storageService,
    );
    final authService = AuthService(apiClient: apiClient, storageService: storageService);
    service = ProductoService(apiClient: apiClient);

    // Iniciar sesión real contra el backend activo para obtener y almacenar el JWT en StorageService
    await authService.login(testEmail, testPassword);
    final hasToken = await storageService.hasToken();
    expect(hasToken, true, reason: 'El token JWT debe almacenarse tras login exitoso');

    // Limpieza preventiva si el código de prueba quedó de una ejecución anterior interrumpida
    try {
      final prods = await service.getProductos();
      for (final p in prods) {
        if (p.codigo == 'COM-TEST-02') {
          await service.deleteProducto(p.id);
        }
      }
    } catch (_) {}
  });

  test('Flutter -> Backend real: listar productos iniciales', () async {
    final prods = await service.getProductos();
    expect(prods.isNotEmpty, true);
    expect(prods.length >= 10, true);
  });

  test('Flutter -> Backend real: consultar producto por ID', () async {
    final prod = await service.getProductoById(1);
    expect(prod.id, 1);
    expect(prod.codigo.isNotEmpty, true);
  });

  test('Flutter -> Backend real: ciclo completo CRUD (Crear, Actualizar, Eliminar)', () async {
    // 1. Crear
    final nuevoPayload = {
      'nombre': 'Disipador CPU Noctua NH-D15',
      'codigo': 'COM-TEST-02',
      'descripcion': 'Doble torre de refrigeración por aire con dos ventiladores NF-A15',
      'precio': 520000.0,
      'cantidad': 6,
      'categoria': 'Componentes',
    };

    final creado = await service.createProducto(nuevoPayload);
    expect(creado.id > 0, true);
    expect(creado.codigo, 'COM-TEST-02');

    // 2. Actualizar
    final updatePayload = {
      'nombre': 'Disipador CPU Noctua NH-D15 chromax.black',
      'codigo': 'COM-TEST-02',
      'descripcion': 'Edición especial completamente negra mate',
      'precio': 590000.0,
      'cantidad': 10,
      'categoria': 'Componentes',
    };

    final actualizado = await service.updateProducto(creado.id, updatePayload);
    expect(actualizado.nombre, 'Disipador CPU Noctua NH-D15 chromax.black');
    expect(actualizado.precio, 590000.0);
    expect(actualizado.cantidad, 10);

    // 3. Eliminar
    await service.deleteProducto(creado.id);

    // 4. Verificar eliminación
    final lista = await service.getProductos();
    expect(lista.any((p) => p.id == creado.id), false);
  });
}
