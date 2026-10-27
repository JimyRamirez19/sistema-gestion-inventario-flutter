import 'package:flutter/material.dart';
import '../core/errors/api_exception.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';

class InventarioController extends ChangeNotifier {
  final ProductoService _service;

  List<Producto> _productos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'Todas';

  InventarioController({ProductoService? service})
      : _service = service ?? ProductoService();

  // Getters
  List<Producto> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // KPIs
  int get totalProductos => _productos.length;
  int get totalUnidades => _productos.fold(0, (sum, p) => sum + p.cantidad);
  double get totalValorInventario => _productos.fold(0.0, (sum, p) => sum + p.valorTotal);
  int get totalBajoStock => _productos.where((p) => p.isLowStock).length;
  int get totalAgotados => _productos.where((p) => p.isOutOfStock).length;

  List<String> get categorias {
    final setCats = <String>{'Todas'};
    for (var p in _productos) {
      if (p.categoria.isNotEmpty) {
        setCats.add(p.categoria);
      }
    }
    return setCats.toList();
  }

  List<Producto> get filteredProductos {
    return _productos.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.codigo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.categoria.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'Todas' ||
          p.categoria.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Load all products from API
  Future<void> cargarProductos({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _productos = await _service.getProductos();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Error inesperado al cargar productos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter setters
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Create product
  Future<Producto> crearProducto(Map<String, dynamic> payload) async {
    try {
      final nuevo = await _service.createProducto(payload);
      _productos.insert(0, nuevo);
      notifyListeners();
      return nuevo;
    } catch (e) {
      rethrow;
    }
  }

  // Update product
  Future<Producto> actualizarProducto(int id, Map<String, dynamic> payload) async {
    try {
      final actualizado = await _service.updateProducto(id, payload);
      final index = _productos.indexWhere((p) => p.id == id);
      if (index != -1) {
        _productos[index] = actualizado;
        notifyListeners();
      }
      return actualizado;
    } catch (e) {
      rethrow;
    }
  }

  // Delete product
  Future<void> eliminarProducto(int id) async {
    try {
      await _service.deleteProducto(id);
      _productos.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Producto? obtenerPorIdLocal(int id) {
    try {
      return _productos.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
