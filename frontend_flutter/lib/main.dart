import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'controllers/inventario_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env configuration safely
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("[ENV] Variables de entorno cargadas exitosamente.");
  } catch (e) {
    debugPrint("[ENV WARNING] No se pudo cargar .env: $e. Se utilizarán valores predeterminados.");
  }

  // Initialize central controller and load initial products from real API
  final inventarioController = InventarioController();
  await inventarioController.cargarProductos();

  runApp(InventarioApp(controller: inventarioController));
}
