import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/producto.dart';

class ProductoService {
  final ApiClient _apiClient;

  ProductoService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Producto>> getProductos() async {
    final response = await _apiClient.get(ApiConstants.productosEndpoint);
    if (response is List) {
      return response.map((item) => Producto.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Producto> getProductoById(int id) async {
    final response = await _apiClient.get('${ApiConstants.productosEndpoint}/$id');
    return Producto.fromJson(response as Map<String, dynamic>);
  }

  Future<Producto> createProducto(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      ApiConstants.productosEndpoint,
      data: payload,
    );
    return Producto.fromJson(response as Map<String, dynamic>);
  }

  Future<Producto> updateProducto(int id, Map<String, dynamic> payload) async {
    final response = await _apiClient.put(
      '${ApiConstants.productosEndpoint}/$id',
      data: payload,
    );
    return Producto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteProducto(int id) async {
    await _apiClient.delete('${ApiConstants.productosEndpoint}/$id');
  }
}
