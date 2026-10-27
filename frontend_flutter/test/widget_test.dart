import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_flutter/app.dart';
import 'package:frontend_flutter/controllers/inventario_controller.dart';
import 'package:frontend_flutter/models/producto.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://127.0.0.1:8000/api');
  });

  test('Modelo Producto cálculo de valorTotal y estados de stock', () {
    final p = Producto(
      id: 1,
      nombre: 'Test Laptop',
      codigo: 'TEC-999',
      precio: 2500000.0,
      cantidad: 4,
      categoria: 'Computadores',
    );

    expect(p.valorTotal, 10000000.0);
    expect(p.isLowStock, true);
    expect(p.isOutOfStock, false);
  });

  testWidgets('Carga inicial de la aplicación InventarioApp', (WidgetTester tester) async {
    final controller = InventarioController();
    await tester.pumpWidget(InventarioApp(controller: controller));
    expect(find.text('Inventario Pro'), findsOneWidget);
    expect(find.text('Indicadores Principales'), findsOneWidget);
  });
}
