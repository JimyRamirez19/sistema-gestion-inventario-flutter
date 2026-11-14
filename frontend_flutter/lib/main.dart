import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'controllers/auth_controller.dart';
import 'controllers/inventario_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga segura de variables de entorno (.env)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("[ENV] Variables de entorno cargadas exitosamente.");
  } catch (e) {
    debugPrint("[ENV WARNING] No se pudo cargar .env: $e. Se utilizarán valores predeterminados.");
  }

  // 1. Inicializar controlador de autenticación y validar persistencia de sesión
  final authController = AuthController();
  await authController.verificarSesionInicial();

  // 2. Inicializar controlador central de inventario
  final inventarioController = InventarioController();

  // 3. Cargar productos ÚNICAMENTE si existe una sesión válida (evita peticiones 401 prematuras)
  if (authController.isAuthenticated) {
    await inventarioController.cargarProductos();
  }

  runApp(InventarioApp(
    authController: authController,
    inventarioController: inventarioController,
  ));
}
