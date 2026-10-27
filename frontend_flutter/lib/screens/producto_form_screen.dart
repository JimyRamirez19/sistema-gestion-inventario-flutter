import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../controllers/inventario_controller.dart';
import '../core/constants/app_colors.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';

class ProductoFormScreen extends StatefulWidget {
  final int? id; // null = create mode, non-null = edit mode
  final InventarioController controller;

  const ProductoFormScreen({
    super.key,
    this.id,
    required this.controller,
  });

  bool get isEditing => id != null;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _descripcionController = TextEditingController();

  bool _isLoadingInitial = false;
  bool _isSubmitting = false;
  String? _serverErrorMessage;

  static const List<String> _categoriasSugeridas = [
    'Computadores',
    'Monitores',
    'Accesorios',
    'Audio',
    'Almacenamiento',
    'Componentes',
    'Impresión',
    'Muebles de Oficina',
    'Redes',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadProductToEdit();
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _categoriaController.dispose();
    _precioController.dispose();
    _cantidadController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadProductToEdit() async {
    setState(() => _isLoadingInitial = true);
    try {
      // Check cache first, then API
      Producto? prod = widget.controller.obtenerPorIdLocal(widget.id!);
      prod ??= await ProductoService().getProductoById(widget.id!);

      _codigoController.text = prod.codigo;
      _nombreController.text = prod.nombre;
      _categoriaController.text = prod.categoria;
      _precioController.text = prod.precio % 1 == 0
          ? prod.precio.toInt().toString()
          : prod.precio.toString();
      _cantidadController.text = prod.cantidad.toString();
      _descripcionController.text = prod.descripcion ?? '';
    } catch (e) {
      _serverErrorMessage = 'No se pudo cargar el producto para editar: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_serverErrorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _serverErrorMessage!,
                                style: const TextStyle(color: AppColors.danger, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Section: Basic identification
                    const Text(
                      'Identificación del Producto',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Código
                    TextFormField(
                      controller: _codigoController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Código único *',
                        hintText: 'Ej. TEC-001, ACC-005',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El código es obligatorio.';
                        }
                        if (value.trim().length < 2) {
                          return 'El código debe tener al menos 2 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto *',
                        hintText: 'Ej. Teclado Mecánico RGB',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Categoría
                    TextFormField(
                      controller: _categoriaController,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        hintText: 'Ej. Accesorios, Monitores...',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La categoría es obligatoria.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Quick category chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _categoriasSugeridas.map((cat) {
                        return ActionChip(
                          label: Text(cat, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppColors.background,
                          side: const BorderSide(color: AppColors.cardBorder),
                          onPressed: () {
                            setState(() {
                              _categoriaController.text = cat;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Section: Commercial details
                    const Text(
                      'Valores y Existencias',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Precio
                        Expanded(
                          child: TextFormField(
                            controller: _precioController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Precio (COP) *',
                              hintText: 'Ej. 450000',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Precio requerido.';
                              }
                              final numVal = double.tryParse(value.trim());
                              if (numVal == null) {
                                return 'Número inválido.';
                              }
                              if (numVal < 0) {
                                return 'No puede ser negativo.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Cantidad
                        Expanded(
                          child: TextFormField(
                            controller: _cantidadController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Cantidad en stock *',
                              hintText: 'Ej. 15',
                              prefixIcon: Icon(Icons.inventory_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Cantidad requerida.';
                              }
                              final intVal = int.tryParse(value.trim());
                              if (intVal == null) {
                                return 'Entero inválido.';
                              }
                              if (intVal < 0) {
                                return 'No puede ser negativo.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section: Optional description
                    const Text(
                      'Información Adicional',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'Detalles técnicos, especificaciones, garantía...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isEditing ? AppColors.accent : AppColors.primary,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(widget.isEditing ? Icons.save : Icons.add_circle_outline),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.isEditing ? 'Guardar Cambios' : 'Registrar Producto',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitForm() async {
    setState(() => _serverErrorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'codigo': _codigoController.text.trim().toUpperCase(),
      'nombre': _nombreController.text.trim(),
      'categoria': _categoriaController.text.trim(),
      'precio': double.parse(_precioController.text.trim()),
      'cantidad': int.parse(_cantidadController.text.trim()),
      'descripcion': _descripcionController.text.trim().isNotEmpty
          ? _descripcionController.text.trim()
          : null,
    };

    try {
      if (widget.isEditing) {
        await widget.controller.actualizarProducto(widget.id!, payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado exitosamente en el backend.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        await widget.controller.crearProducto(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto registrado exitosamente en el backend.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverErrorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
