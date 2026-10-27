import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/inventario_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/formatters.dart';
import '../widgets/metric_card.dart';
import '../widgets/state_views.dart';

class DashboardScreen extends StatelessWidget {
  final InventarioController controller;

  const DashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.inventory_2, color: AppColors.accentLight, size: 22),
                SizedBox(width: 10),
                Text('Inventario Pro'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar datos',
                onPressed: () => controller.cargarProductos(),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Información de API',
                onPressed: () => _mostrarInfoDialog(context),
              ),
            ],
          ),
          body: controller.isLoading
              ? const LoadingView(message: 'Consultando datos del backend...')
              : controller.errorMessage != null
                  ? ErrorView(
                      message: controller.errorMessage!,
                      onRetry: () => controller.cargarProductos(),
                    )
                  : RefreshIndicator(
                      onRefresh: () => controller.cargarProductos(),
                      color: AppColors.accent,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header banner
                            _buildHeaderBanner(context),
                            const SizedBox(height: 20),

                            // KPI Section Title
                            const Text(
                              'Indicadores Principales',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 3 Required KPI Cards
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 600;
                                return isWide
                                    ? Row(
                                        children: [
                                          Expanded(child: _buildCardTotalProductos()),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildCardTotalUnidades()),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildCardValorTotal()),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _buildCardValorTotal(),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(child: _buildCardTotalProductos()),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildCardTotalUnidades()),
                                            ],
                                          ),
                                        ],
                                      );
                              },
                            ),

                            // Low stock alert badge if any
                            if (controller.totalBajoStock > 0 || controller.totalAgotados > 0) ...[
                              const SizedBox(height: 12),
                              _buildAlertBanner(context),
                            ],

                            const SizedBox(height: 24),

                            // Quick Navigation Buttons
                            const Text(
                              'Acceso Rápido',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.push('/productos'),
                                    icon: const Icon(Icons.list_alt),
                                    label: const Text('Gestionar Productos'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.push('/productos/nuevo'),
                                    icon: const Icon(Icons.add_circle_outline),
                                    label: const Text('Nuevo Producto'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // Recent products preview
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Productos Registrados',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => context.push('/productos'),
                                  icon: const Icon(Icons.arrow_forward, size: 16),
                                  label: const Text('Ver todos'),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            if (controller.productos.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Center(
                                    child: Text(
                                      'No hay productos registrados en el sistema.',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: controller.productos.take(5).length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final prod = controller.productos[index];
                                  return Card(
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.devices, color: Colors.white, size: 20),
                                      ),
                                      title: Text(
                                        prod.nombre,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${prod.codigo} • ${prod.categoria} • ${prod.cantidad} unid.',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      trailing: Text(
                                        Formatters.formatCurrency(prod.precio),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      onTap: () => context.push('/productos/${prod.id}'),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (idx) {
              if (idx == 1) context.push('/productos');
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Inventario',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ELECTIVA PROFESIONAL I • PARCIAL II',
                    style: TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gestión Comercial de Inventario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sincronizado en tiempo real con API REST y SQLite',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTotalProductos() {
    return MetricCard(
      title: 'Total Productos',
      value: Formatters.formatInteger(controller.totalProductos),
      subtitle: '${controller.categorias.length - 1} categorías registradas',
      icon: Icons.category_outlined,
      iconColor: AppColors.info,
      iconBgColor: const Color(0xFFDBEAFE),
    );
  }

  Widget _buildCardTotalUnidades() {
    return MetricCard(
      title: 'Unidades en Stock',
      value: Formatters.formatInteger(controller.totalUnidades),
      subtitle: 'Unidades físicas disponibles',
      icon: Icons.all_inbox_outlined,
      iconColor: AppColors.accent,
      iconBgColor: const Color(0xFFCCFBF1),
    );
  }

  Widget _buildCardValorTotal() {
    return MetricCard(
      title: 'Valor Total del Inventario',
      value: Formatters.formatCurrency(controller.totalValorInventario),
      subtitle: 'Suma de (Precio × Cantidad) de todos los productos',
      icon: Icons.monetization_on_outlined,
      iconColor: AppColors.success,
      iconBgColor: const Color(0xFFD1FAE5),
    );
  }

  Widget _buildAlertBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Atención: ${controller.totalBajoStock} producto(s) con bajo stock (≤ 5 unid.) y ${controller.totalAgotados} agotado(s).',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Información del Sistema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backend API REST:', style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(ApiConstants.baseUrl, style: const TextStyle(color: AppColors.accent)),
            const SizedBox(height: 12),
            const Text('Persistencia:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('SQLite (inventario.db físico)'),
            const SizedBox(height: 12),
            const Text('Módulos Implementados:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text(
              '• Dio con interceptores y timeouts\n'
              '• go_router con navegación parametrizada\n'
              '• flutter_dotenv para URL base\n'
              '• Validación robusta y cálculo reactivo',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
