import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'controllers/auth_controller.dart';
import 'controllers/inventario_controller.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

class InventarioApp extends StatefulWidget {
  final AuthController? authController;
  final InventarioController? inventarioController;
  final InventarioController? controller; // Alias para compatibilidad con pruebas

  const InventarioApp({
    super.key,
    this.authController,
    this.inventarioController,
    this.controller,
  });

  @override
  State<InventarioApp> createState() => _InventarioAppState();
}

class _InventarioAppState extends State<InventarioApp> {
  late final AuthController _authController;
  late final InventarioController _inventarioController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController();
    _inventarioController =
        widget.inventarioController ?? widget.controller ?? InventarioController();
    _router = createRouter(_authController, _inventarioController);
    _authController.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    // Cuando el usuario inicia sesión y el inventario aún no está cargado, cargar productos
    if (_authController.isAuthenticated &&
        _inventarioController.productos.isEmpty &&
        !_inventarioController.isLoading) {
      _inventarioController.cargarProductos(silent: true);
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sistema de Gestión de Inventario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
