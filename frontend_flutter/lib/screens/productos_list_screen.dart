import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/inventario_controller.dart';
import '../core/constants/app_colors.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/producto_card.dart';
import '../widgets/state_views.dart';

class ProductosListScreen extends StatefulWidget {
  final InventarioController controller;

  const ProductosListScreen({super.key, required this.controller});

  @override
  State<ProductosListScreen> createState() => _ProductosListScreenState();
}

class _ProductosListScreenState extends State<ProductosListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final productos = controller.filteredProductos;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Catálogo de Productos'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refrescar',
                onPressed: () => controller.cargarProductos(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & filter header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => controller.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, código o categoría...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  controller.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Category chips
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.categorias.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = controller.categorias[index];
                          final isSelected = controller.selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.accent,
                            backgroundColor: AppColors.background,
                            side: BorderSide(
                              color: isSelected ? AppColors.accent : AppColors.cardBorder,
                            ),
                            onSelected: (_) => controller.setSelectedCategory(cat),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),

              // Product list view
              Expanded(
                child: controller.isLoading
                    ? const LoadingView(message: 'Cargando listado de productos...')
                    : controller.errorMessage != null
                        ? ErrorView(
                            message: controller.errorMessage!,
                            onRetry: () => controller.cargarProductos(),
                          )
                        : productos.isEmpty
                            ? EmptyView(
                                title: controller.searchQuery.isNotEmpty || controller.selectedCategory != 'Todas'
                                    ? 'Sin resultados para la búsqueda'
                                    : 'Inventario vacío',
                                subtitle: controller.searchQuery.isNotEmpty
                                    ? 'Intenta con otro término o limpia los filtros.'
                                    : 'No hay productos registrados actualmente en la base de datos.',
                                actionLabel: 'Registrar Producto',
                                onAction: () => context.push('/productos/nuevo'),
                              )
                            : RefreshIndicator(
                                onRefresh: () => controller.cargarProductos(),
                                color: AppColors.accent,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                                  itemCount: productos.length,
                                  itemBuilder: (context, index) {
                                    final producto = productos[index];
                                    return ProductoCard(
                                      producto: producto,
                                      onTap: () => context.push('/productos/${producto.id}'),
                                      onEdit: () => context.push('/productos/${producto.id}/editar'),
                                      onDelete: () => _handleDelete(context, producto),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/productos/nuevo'),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Producto'),
          ),
        );
      },
    );
  }

  Future<void> _handleDelete(BuildContext context, producto) async {
    final confirmed = await ConfirmDeleteDialog.show(context, producto);
    if (confirmed == true && context.mounted) {
      try {
        await widget.controller.eliminarProducto(producto.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto "${producto.nombre}" eliminado exitosamente.'),
              backgroundColor: AppColors.success,
            ),
          );
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
