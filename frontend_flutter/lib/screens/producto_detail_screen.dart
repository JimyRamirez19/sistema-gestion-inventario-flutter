import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/inventario_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/state_views.dart';

class ProductoDetailScreen extends StatefulWidget {
  final int id;
  final InventarioController controller;

  const ProductoDetailScreen({
    super.key,
    required this.id,
    required this.controller,
  });

  @override
  State<ProductoDetailScreen> createState() => _ProductoDetailScreenState();
}

class _ProductoDetailScreenState extends State<ProductoDetailScreen> {
  Producto? _producto;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    // First try fast local cache
    final cached = widget.controller.obtenerPorIdLocal(widget.id);
    if (cached != null) {
      setState(() => _producto = cached);
    } else {
      setState(() => _isLoading = true);
    }

    // Always fetch fresh from API to ensure accuracy
    try {
      final fresh = await ProductoService().getProductoById(widget.id);
      if (mounted) {
        setState(() {
          _producto = fresh;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted && _producto == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Producto')),
        body: const LoadingView(message: 'Consultando detalle desde el backend...'),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Producto')),
        body: ErrorView(
          message: _errorMessage!,
          onRetry: _loadDetail,
        ),
      );
    }

    final p = _producto;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Producto no encontrado')),
        body: const Center(child: Text('El producto solicitado no existe o fue eliminado.')),
      );
    }

    Color stockColor = AppColors.success;
    String stockText = 'En Stock (${p.cantidad} unidades)';
    if (p.isOutOfStock) {
      stockColor = AppColors.danger;
      stockText = 'Agotado (0 unidades)';
    } else if (p.isLowStock) {
      stockColor = AppColors.warning;
      stockText = 'Bajo Stock (${p.cantidad} unidades)';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(p.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar producto',
            onPressed: () async {
              await context.push('/productos/${p.id}/editar');
              _loadDetail();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFCA5A5)),
            tooltip: 'Eliminar producto',
            onPressed: () => _handleDelete(context, p),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code & Category chips
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.codigo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    p.categoria,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: #${p.id}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Product Name
            Text(
              p.nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Price & Stock Overview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Precio Unitario',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        Text(
                          Formatters.formatCurrency(p.precio),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.cardBorder),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Disponibilidad',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stockText,
                            style: TextStyle(
                              color: stockColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.cardBorder),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Valor Total en Stock',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        Text(
                          Formatters.formatCurrency(p.valorTotal),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description Section
            const Text(
              'Descripción del Producto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  (p.descripcion != null && p.descripcion!.isNotEmpty)
                      ? p.descripcion!
                      : 'Sin descripción detallada registrada para este producto.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: (p.descripcion != null && p.descripcion!.isNotEmpty)
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDelete(context, p),
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    label: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/productos/${p.id}/editar');
                      _loadDetail();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Producto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, Producto p) async {
    final confirmed = await ConfirmDeleteDialog.show(context, p);
    if (confirmed == true && context.mounted) {
      try {
        await widget.controller.eliminarProducto(p.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto "${p.nombre}" eliminado exitosamente.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(); // Return to previous screen
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }
}
