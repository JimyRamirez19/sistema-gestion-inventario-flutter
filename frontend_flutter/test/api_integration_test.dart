import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_flutter/core/network/api_client.dart';
import 'package:frontend_flutter/services/producto_service.dart';

void main() {
  late ProductoService service;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://127.0.0.1:8000/api');
    final apiClient = ApiClient(baseUrlOverride: 'http://127.0.0.1:8000/api');
    service = ProductoService(apiClient: apiClient);
  });

  test('Flutter -> Backend real: listar productos iniciales', () async {
    final prods = await service.getProductos();
    expect(prods.isNotEmpty, true);
    expect(prods.length >= 10, true);
  });

  test('Flutter -> Backend real: consultar producto por ID', () async {
    final prod = await service.getProductoById(1);
    expect(prod.id, 1);
    expect(prod.codigo.isNotEmpty, true);
  });

  test('Flutter -> Backend real: ciclo completo CRUD (Crear, Actualizar, Eliminar)', () async {
    // 1. Crear
    final nuevoPayload = {
      'nombre': 'Disipador CPU Noctua NH-D15',
      'codigo': 'COM-TEST-02',
      'descripcion': 'Doble torre de refrigeración por aire con dos ventiladores NF-A15',
      'precio': 520000.0,
      'cantidad': 6,
      'categoria': 'Componentes',
    };

    final creado = await service.createProducto(nuevoPayload);
    expect(creado.id > 0, true);
    expect(creado.codigo, 'COM-TEST-02');

    // 2. Actualizar
    final updatePayload = {
      'nombre': 'Disipador CPU Noctua NH-D15 chromax.black',
      'codigo': 'COM-TEST-02',
      'descripcion': 'Edición especial completamente negra mate',
      'precio': 590000.0,
      'cantidad': 10,
      'categoria': 'Componentes',
    };

    final actualizado = await service.updateProducto(creado.id, updatePayload);
    expect(actualizado.nombre, 'Disipador CPU Noctua NH-D15 chromax.black');
    expect(actualizado.precio, 590000.0);
    expect(actualizado.cantidad, 10);

    // 3. Eliminar
    await service.deleteProducto(creado.id);

    // 4. Verificar eliminación
    final lista = await service.getProductos();
    expect(lista.any((p) => p.id == creado.id), false);
  });
}
