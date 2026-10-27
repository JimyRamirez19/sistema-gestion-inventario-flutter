import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'controllers/inventario_controller.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

class InventarioApp extends StatefulWidget {
  final InventarioController controller;

  const InventarioApp({super.key, required this.controller});

  @override
  State<InventarioApp> createState() => _InventarioAppState();
}

class _InventarioAppState extends State<InventarioApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.controller);
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
