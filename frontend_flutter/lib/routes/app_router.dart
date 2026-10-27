import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/inventario_controller.dart';
import '../screens/dashboard_screen.dart';
import '../screens/productos_list_screen.dart';
import '../screens/producto_detail_screen.dart';
import '../screens/producto_form_screen.dart';

GoRouter createRouter(InventarioController controller) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => DashboardScreen(controller: controller),
      ),
      GoRoute(
        path: '/productos',
        name: 'productos_list',
        builder: (context, state) => ProductosListScreen(controller: controller),
        routes: [
          GoRoute(
            path: 'nuevo',
            name: 'producto_nuevo',
            builder: (context, state) => ProductoFormScreen(controller: controller),
          ),
          GoRoute(
            path: ':id',
            name: 'producto_detalle',
            builder: (context, state) {
              final idStr = state.pathParameters['id'];
              final id = int.tryParse(idStr ?? '') ?? 0;
              return ProductoDetailScreen(id: id, controller: controller);
            },
            routes: [
              GoRoute(
                path: 'editar',
                name: 'producto_editar',
                builder: (context, state) {
                  final idStr = state.pathParameters['id'];
                  final id = int.tryParse(idStr ?? '') ?? 0;
                  return ProductoFormScreen(id: id, controller: controller);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('No se encontró la ruta: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ir al Inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
