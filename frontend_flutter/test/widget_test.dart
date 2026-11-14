import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_flutter/app.dart';
import 'package:frontend_flutter/controllers/auth_controller.dart';
import 'package:frontend_flutter/controllers/inventario_controller.dart';
import 'package:frontend_flutter/models/producto.dart';
import 'package:frontend_flutter/models/usuario.dart';
import 'package:frontend_flutter/screens/login_screen.dart';
import 'package:frontend_flutter/widgets/session_info_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://127.0.0.1:8000/api');
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  // ==========================================================================
  // PRUEBAS DE MODELO EXISTENTES (PARCIAL 2)
  // ==========================================================================

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

  // ==========================================================================
  // PRUEBAS DE PANTALLA DE LOGIN DEFINITIVA (SUB-PASO 3.4)
  // ==========================================================================

  testWidgets('1. Renderizado de LoginScreen: visualiza banner, campos y botón', (WidgetTester tester) async {
    final authController = AuthController(initialAuthenticated: false);

    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(authController: authController),
    ));

    // Validar identidad visual y componentes
    expect(find.text('Inventario Pro'), findsOneWidget);
    expect(find.text('Ingreso de Usuario'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Autenticación Segura mediante JWT y FastAPI'), findsOneWidget);
  });

  testWidgets('2. Validaciones de formulario en LoginScreen: campos obligatorios y formato', (WidgetTester tester) async {
    final authController = AuthController(initialAuthenticated: false);

    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(authController: authController),
    ));

    // Intentar enviar formulario vacío
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(find.text('El correo electrónico es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);

    // Ingresar formato inválido de correo
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo electrónico'), 'correo_sin_arroba');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Ingrese un formato de correo válido (ej. usuario@dominio.com)'), findsOneWidget);
  });

  testWidgets('3. Alternancia de visibilidad de contraseña en LoginScreen', (WidgetTester tester) async {
    final authController = AuthController(initialAuthenticated: false);

    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(authController: authController),
    ));

    // Por defecto el campo de contraseña debe ser privado (obscureText: true)
    final passwordFieldFinder = find.widgetWithText(TextFormField, 'Contraseña');
    TextField textField = tester.widget<TextField>(
      find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
    );
    expect(textField.obscureText, isTrue);

    // Presionar botón para mostrar contraseña
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pumpAndSettle();

    textField = tester.widget<TextField>(
      find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
    );
    expect(textField.obscureText, isFalse);

    // Presionar botón para volver a ocultar contraseña
    await tester.tap(find.byTooltip('Ocultar contraseña'));
    await tester.pumpAndSettle();

    textField = tester.widget<TextField>(
      find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
    );
    expect(textField.obscureText, isTrue);
  });

  // ==========================================================================
  // PRUEBAS DE MODAL DE INFORMACIÓN DE SESIÓN (REQUISITO 4.6)
  // ==========================================================================

  testWidgets('4. Visualización de información del usuario en SessionInfoDialog', (WidgetTester tester) async {
    final authController = AuthController(
      initialAuthenticated: true,
      initialUsuario: const Usuario(
        id: 1,
        nombre: 'Administrador del Sistema',
        email: 'admin@inventario.com',
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SessionInfoDialog(authController: authController),
      ),
    ));

    // Validar presencia de información del usuario y seguridad
    expect(find.text('Información de Sesión'), findsOneWidget);
    expect(find.text('Administrador del Sistema'), findsOneWidget);
    expect(find.text('admin@inventario.com'), findsOneWidget);
    expect(find.text('Sesión activa con JWT'), findsOneWidget);
    expect(find.textContaining('Token JWT almacenado y cifrado en almacenamiento seguro'), findsOneWidget);
    expect(find.text('Cerrar Sesión'), findsOneWidget);
  });

  // ==========================================================================
  // PRUEBAS DE INTEGRACIÓN EN EL DASHBOARD Y CIERRE DE SESIÓN
  // ==========================================================================

  testWidgets('5. Carga inicial con sesión activa muestra saludo y badge JWT en Dashboard', (WidgetTester tester) async {
    final authController = AuthController(
      initialAuthenticated: true,
      initialUsuario: const Usuario(
        id: 1,
        nombre: 'Admin Inventario',
        email: 'admin@inventario.com',
      ),
    );
    final controller = InventarioController();

    await tester.pumpWidget(InventarioApp(
      authController: authController,
      inventarioController: controller,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Inventario Pro'), findsOneWidget);
    expect(find.text('Hola, Admin Inventario'), findsOneWidget);
    expect(find.text('JWT ACTIVO'), findsOneWidget);
    expect(find.text('Indicadores Principales'), findsOneWidget);
  });

  testWidgets('6. Cierre de sesión desde Dashboard redirige obligatoriamente a LoginScreen', (WidgetTester tester) async {
    final authController = AuthController(
      initialAuthenticated: true,
      initialUsuario: const Usuario(
        id: 1,
        nombre: 'Usuario Demo',
        email: 'demo@inventario.com',
      ),
    );
    final controller = InventarioController();

    await tester.pumpWidget(InventarioApp(
      authController: authController,
      inventarioController: controller,
    ));
    await tester.pumpAndSettle();

    // Comprobar que estamos en el Dashboard
    expect(find.text('Hola, Usuario Demo'), findsOneWidget);

    // Abrir diálogo de información de sesión desde el AppBar
    await tester.tap(find.byTooltip('Mi Sesión (JWT)'));
    await tester.pumpAndSettle();

    expect(find.text('Información de Sesión'), findsOneWidget);
    expect(find.text('demo@inventario.com'), findsOneWidget);

    // Presionar botón de Cerrar Sesión
    await tester.tap(find.text('Cerrar Sesión'));
    await tester.pumpAndSettle();

    // GoRouter redirige de inmediato a la pantalla de login
    expect(find.text('Ingreso de Usuario'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Indicadores Principales'), findsNothing);
  });
}
