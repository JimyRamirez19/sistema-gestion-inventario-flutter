# INFORME TÉCNICO FINAL — IMPLEMENTACIÓN DE AUTENTICACIÓN JWT EN SISTEMA DE GESTIÓN DE INVENTARIOS

**Proyecto:** Sistema de Gestión de Inventario — API REST (FastAPI) + Aplicación Móvil (Flutter)  
**Taller:** Implementación de Seguridad y Autenticación Basada en JSON Web Tokens (JWT)  
**Asignatura:** Electiva Profesional I - Desarrollo de Aplicaciones Móviles  
**Fecha:** Noviembre 2026  
**Rama de Desarrollo:** `feature/taller_jwt`  
**Repositorio:** [sistema-gestion-inventario-flutter](https://github.com/JimyRamirez19/sistema-gestion-inventario-flutter)  

---

## 1. RESUMEN EJECUTIVO Y OBJETIVOS

El presente documento constituye el informe técnico de cierre y entrega académica del taller de autenticación mediante **JSON Web Tokens (JWT)** sobre la arquitectura cliente-servidor previamente desarrollada para el Sistema de Gestión de Inventario.

### 1.1 Objetivo General
Proteger integralmente la infraestructura de la solución desacoplada, garantizando que el acceso a los recursos comerciales (productos, métricas e inventarios) y a las operaciones de mutación de datos (CRUD) requiera una identidad verificada y un token de sesión criptográficamente firmado, administrado con altos estándares de seguridad tanto en el servidor backend (FastAPI) como en el cliente móvil (Flutter).

### 1.2 Objetivos Específicos Alcanzados
1. **Seguridad en Backend:** Implementar un modelo de usuarios en base de datos SQLite con almacenamiento de credenciales mediante funciones de derivación de claves con sal (*hashing* robusto con bcrypt).
2. **Ciclo de Vida JWT:** Implementar endpoints de autenticación (`POST /api/auth/login`) y perfil de usuario (`GET /api/auth/me`), emitiendo tokens firmados digitalmente bajo el estándar RFC 7519 (algoritmo HMAC-SHA256) con expiración controlada.
3. **Control de Acceso a Endpoints:** Proteger los cinco endpoints CRUD de productos (`GET`, `POST`, `PUT`, `DELETE`) mediante dependencias de inyección que validan la presencia y vigencia del encabezado HTTP `Authorization: Bearer <token>`.
4. **Almacenamiento Criptográfico Móvil:** Implementar en Flutter un esquema de almacenamiento segregado: el token JWT se resguarda exclusivamente en el almacén seguro del sistema operativo a través de `flutter_secure_storage` (cifrado RSA/AES mediante Android Keystore), mientras que datos no sensibles del perfil residen en `shared_preferences`.
5. **Interceptores y Automatización de Red:** Centralizar en el cliente HTTP Dio un `AuthInterceptor` que inyecta automáticamente el token Bearer en cada petición saliente y gestiona de forma reactiva las respuestas HTTP 401 Unauthorized (limpieza de credenciales y redirección).
6. **Navegación Protegida (Route Guards):** Configurar en GoRouter un esquema declarativo de protección de rutas basado en un `AuthController` reactivo (`ChangeNotifier`), impidiendo que usuarios anónimos accedan al Dashboard o vistas CRUD y redirigiendo a los usuarios autenticados fuera de la pantalla de inicio de sesión.
7. **Interfaz de Usuario y Experiencia (UX/UI):** Diseñar una pantalla de inicio de sesión (`LoginScreen`) coherente con la identidad visual de la aplicación, complementada con un diálogo de información de sesión (`SessionInfoDialog`) y capacidades de cierre de sesión seguro desde el Dashboard.
8. **Validación Integral de Escenarios (7/7 Aprobados):** Superar el 100% de las suites de pruebas automatizadas (15 pruebas en backend con pytest y 16 pruebas en Flutter con flutter test) y validar exitosamente los 7 escenarios docentes mediante pruebas manuales en emulador Android Pixel 8, confirmando el cumplimiento total de los requisitos de seguridad, control de acceso, persistencia de sesión tras reinicio y cierre seguro.

---

## 2. ARQUITECTURA DE LA SOLUCIÓN

La solución mantiene una arquitectura desacoplada y orientada a servicios, donde el backend expone una API REST sin estado (*stateless*) y el cliente Flutter conserva la reactividad y gestión de estado local:

```
+-----------------------------------------------------------------------------------+
|                            ARQUITECTURA CLIENTE - SERVIDOR                        |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|  [ CLIENTE FLUTTER ] (Material 3 + GoRouter + Dio)                                |
|    |                                                                              |
|    +--> UI Screens: LoginScreen <---> DashboardScreen <---> Productos CRUD        |
|    |           ^                            ^                                     |
|    |           |                            |                                     |
|    +--> AuthController (ChangeNotifier) ---> Escucha estado y notifica a GoRouter |
|    |           |                                                                  |
|    |           v                                                                  |
|    +--> StorageService (Instancia Única Compartida):                              |
|    |       * flutter_secure_storage -> [ Almacén Seguro Keystore: JWT ]           |
|    |       * shared_preferences    -> [ Metadatos: Nombre, Email, ID ]            |
|    |           |                                                                  |
|    |           v                                                                  |
|    +--> Dio HTTP Client + AuthInterceptor                                         |
|            |  (Inyecta Authorization: Bearer <jwt>)                               |
|            |  (Captura 401 Unauthorized -> Dispara onSessionExpired)              |
|            |                                                                      |
+------------|----------------------------------------------------------------------+
             | Red TCP/IP (HTTP REST JSON)
             v
+-----------------------------------------------------------------------------------+
|  [ SERVIDOR FASTAPI ] (Python 3.14 + Uvicorn)                                     |
|    |                                                                              |
|    +--> Middlewares: CORS (Cross-Origin Resource Sharing)                         |
|    |                                                                              |
|    +--> Rutas de Autenticación:                                                   |
|    |       * POST /api/auth/login -> Valida bcrypt, emite JWT HS256               |
|    |       * GET  /api/auth/me    -> Requiere get_current_user (valida token)     |
|    |                                                                              |
|    +--> Rutas Protegidas de Inventario:                                           |
|    |       * GET, POST, PUT, DELETE /api/productos -> Inyección Depends(Auth)     |
|    |                                                                              |
|    +--> Capa Criptográfica (auth.py):                                             |
|    |       * passlib (bcrypt) -> hash_password(), verify_password()               |
|    |       * PyJWT            -> create_access_token(), get_current_user()         |
|    |                                                                              |
|    +--> Capa de Persistencia: SQLAlchemy ORM (models.py, crud.py)                 |
|            |                                                                      |
|            v                                                                      |
|  [ BASE DE DATOS SQLITE ] (inventario.db)                                         |
|       * Tabla 'usuarios'  (id, nombre, email, password_hash, rol, activo)         |
|       * Tabla 'productos' (id, nombre, codigo, precio, cantidad, categoria)       |
+-----------------------------------------------------------------------------------+
```

---

## 3. IMPLEMENTACIÓN TÉCNICA DEL BACKEND

### 3.1 Modelo de Datos del Usuario (`backend/models.py`)
Se incorporó la entidad `Usuario` mapeada mediante SQLAlchemy ORM:

```python
class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nombre = Column(String(120), nullable=False)
    email = Column(String(120), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    rol = Column(String(50), nullable=False, default="admin")
    activo = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
```

**Aspectos clave:**
- `email`: Campo único e indexado para búsquedas eficientes en el login.
- `password_hash`: Almacena la cadena cifrada generada por bcrypt; nunca se guarda texto plano.
- `activo`: Bandera booleana para habilitar o inhabilitar accesos sin eliminar registros.

### 3.2 Esquemas Pydantic v2 (`backend/schemas.py`)
Se implementaron esquemas para validación estricta y serialización de peticiones y respuestas:
- `UsuarioBase`, `UsuarioCreate`, `UsuarioResponse`: Definen los campos públicos, excluyendo deliberadamente cualquier representación del hash de la contraseña en las respuestas.
- `Token`: Modela la estructura de salida tras un login exitoso (`access_token`, `token_type`, y el objeto `usuario`).
- `TokenData`: Valida las afirmaciones (*claims*) del JWT durante la decodificación (`email`).
- `LoginRequest`: Valida que la solicitud de inicio de sesión contenga un correo válido y una contraseña no vacía.

### 3.3 Módulo de Seguridad y Criptografía (`backend/auth.py`)
Centraliza las operaciones criptográficas conforme a los estándares de la industria:
1. **Hashing de Contraseñas:** Se utiliza `passlib.context.CryptContext(schemes=["bcrypt"], deprecated="auto")`.
   - `hash_password(plain_password: str) -> str`: Genera un hash con sal dinámica y costo computacional adaptativo.
   - `verify_password(plain_password: str, hashed_password: str) -> bool`: Compara la contraseña ingresada contra el hash almacenado en tiempo constante para mitigar ataques de temporización (*timing attacks*).
2. **Emisión de Tokens JWT:** Se utiliza `PyJWT`:
   - `create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str`:
     - Inyecta el campo `sub` (identificador principal: correo del usuario).
     - Establece el tiempo de expiración `exp` calculado a partir de `ACCESS_TOKEN_EXPIRE_MINUTES`.
     - Firma criptográficamente el token con el algoritmo `HS256` utilizando la `SECRET_KEY` configurada en las variables de entorno.
3. **Inyección de Dependencias para Protección de Rutas:**
   - Se utiliza `OAuth2PasswordBearer(tokenUrl="/api/auth/login")`.
   - `get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> Usuario`:
     - Intercepta el encabezado `Authorization: Bearer <token>`.
     - Decodifica y verifica la firma con la clave simétrica.
     - Captura `jwt.ExpiredSignatureError` (devolviendo HTTP 401: *"El token de autenticación ha expirado"*).
     - Captura `jwt.InvalidTokenError` (devolviendo HTTP 401: *"Token de autenticación inválido"*).
     - Verifica la existencia y estado activo del usuario en la base de datos.

### 3.4 Endpoints de Autenticación y Protección CRUD (`backend/main.py`)
1. **`POST /api/auth/login`:**
   - Recibe `LoginRequest` (email y password).
   - Busca el usuario por correo y verifica la contraseña con bcrypt.
   - Si las credenciales no coinciden o el usuario está inactivo, responde HTTP 401 Unauthorized.
   - Si son válidas, genera el JWT y retorna el token junto con el perfil del usuario.
2. **`GET /api/auth/me`:**
   - Endpoint protegido mediante `current_user: Usuario = Depends(get_current_user)`.
   - Retorna la información del usuario en sesión (`UsuarioResponse`).
3. **Protección de los 5 Endpoints CRUD:**
   - `GET /api/productos`: Protegido con `Depends(get_current_user)`.
   - `GET /api/productos/{id}`: Protegido con `Depends(get_current_user)`.
   - `POST /api/productos`: Protegido con `Depends(get_current_user)`.
   - `PUT /api/productos/{id}`: Protegido con `Depends(get_current_user)`.
   - `DELETE /api/productos/{id}`: Protegido con `Depends(get_current_user)`.

### 3.5 Inicialización e Idempotencia (`backend/seed_data.py` y `lifespan`)
Durante el arranque de FastAPI, el evento `lifespan` ejecuta secuencialmente:
1. `seed_initial_user(db)`: Comprueba si existe el usuario administrador definido en las variables de entorno (`SEED_ADMIN_EMAIL`). Si no existe, lo crea con su contraseña cifrada con bcrypt. Si ya existe, no duplica ni modifica datos (idempotencia garantizada).
2. `seed_initial_products(db)`: Si la tabla de productos está vacía, inserta el catálogo comercial de 12 productos iniciales.

---

## 4. IMPLEMENTACIÓN TÉCNICA DE FLUTTER

### 4.1 Arquitectura de Almacenamiento Seguro (`frontend_flutter/lib/services/storage_service.dart`)
Se aplicó el principio de segregación de responsabilidades y mínima exposición:
- **`FlutterSecureStorage` (JWT Exclusivo):**
  - **Configuración de Android:**
    ```dart
    static const AndroidOptions _defaultAndroidOptions = AndroidOptions(
      encryptedSharedPreferences: false,
      resetOnError: false,
    );
    ```
  - **Justificación técnica:** Utiliza el mecanismo estándar de cifrado RSA/AES respaldado por el Android Keystore del sistema operativo. Esto evita las incompatibilidades y pérdida de llaves que experimenta la librería `AndroidX Security Crypto` (`encryptedSharedPreferences: true`) al matar procesos en emuladores y dispositivos Android.
  - **Manejo de borrado:** `resetOnError` se mantiene en `false` para evitar la eliminación accidental e irreversible de las credenciales ante fallas transitorias de lectura.
  - Métodos implementados: `saveToken(token)`, `getToken()`, `hasToken()`, `deleteToken()`.
  - **Principio de seguridad:** El token JWT no se escribe en texto plano en archivos SharedPreferences ni en almacenamiento volátil no cifrado.
  - **Trazas de diagnóstico:** Cada operación emite registros claros (`debugPrint`) indicando si el token fue guardado, recuperado o eliminado con éxito, incluyendo trazas de error (`stackTrace`).
- **`SharedPreferences` (Datos no sensibles de sesión):**
  - Almacena exclusivamente metadatos del usuario (`user_name`, `user_email`, `user_id`, `is_authenticated`).
  - Métodos: `saveUserData(id, name, email)`, `getUserData()`, `getUserName()`, `getUserEmail()`, `getUserId()`, `isAuthenticated()`, `clearUserData()`.
- **Limpieza Unificada (`clearAll`):** Elimina atómicamente el token seguro y los metadatos de SharedPreferences al cerrar sesión.

### 4.2 Servicio de Autenticación (`frontend_flutter/lib/services/auth_service.dart`)
- `login(String email, String password)`: Realiza la petición `POST /api/auth/login`. Al recibir un HTTP 200, orquesta el almacenamiento del JWT en `StorageService` y de los datos del usuario en `SharedPreferences`.
- `getPerfil()`: Realiza la petición `GET /api/auth/me`. Permite al frontend validar contra el backend si un token almacenado previamente sigue siendo válido o ha sido revocado/expirado.
- `logout()`: Ejecuta `StorageService.clearAll()` para purgar los datos locales.
- **Manejo de Errores y Seguridad:** Captura `DioException`, transformando errores HTTP en mensajes amigables para el usuario. **Nunca imprime ni registra contraseñas ni tokens en consola.**

### 4.3 Interceptor Centralizado de Dio (`frontend_flutter/lib/core/network/auth_interceptor.dart`)
- **`onRequest`:** Consulta asíncronamente `storageService.getToken()`. Si existe un token, inyecta la cabecera `Authorization: Bearer <token>`. Evita inyectar el encabezado en la ruta pública de login para prevenir redundancias.
- **`onError`:** Detecta si la respuesta del servidor es HTTP 401 Unauthorized y no corresponde al endpoint de login. En dicho caso:
  1. Invoca el callback reactivo `onSessionExpired?.call()`.
  2. Ejecuta `storageService.clearAll()` para remover el token expirado.
  3. Propaga el error para que la interfaz notifique al usuario.

### 4.4 Controlador Reactivo de Sesión (`frontend_flutter/lib/controllers/auth_controller.dart`)
Hereda de `ChangeNotifier` y expone el estado global de autenticación:
- **Instancia Compartida (Factory Pattern):**
  Implementa un constructor de fábrica que garantiza que `AuthController`, `AuthService`, `ApiClient` y `AuthInterceptor` utilicen exactamente la misma instancia de `StorageService` en memoria:
  ```dart
  factory AuthController({
    AuthService? authService,
    StorageService? storageService,
    bool initialAuthenticated = false,
    Usuario? initialUsuario,
  }) {
    final sharedStorage = storageService ?? (authService?.storageService ?? StorageService());
    final resolvedAuthService = authService ?? AuthService(storageService: sharedStorage);
    return AuthController._(
      authService: resolvedAuthService,
      storageService: sharedStorage,
      initialAuthenticated: initialAuthenticated,
      initialUsuario: initialUsuario,
    );
  }
  ```
- **Estados:** `Usuario? usuarioActual`, `bool isAuthenticated`, `bool isLoading`, `bool isInitialized`, `String? errorMessage`.
- **`verificarSesionInicial()` con Diferenciación Estricta:**
  1. Comprueba si existe un token mediante `await _storageService.hasToken()`. Si no existe, finaliza con `_isAuthenticated = false`.
  2. Si existe, valida el token con el backend invocando `await _authService.getPerfil()` (`GET /api/auth/me`).
  3. **Respuesta exitosa (HTTP 200):** Restaura el usuario (`_usuarioActual = usuario`), confirma `_isAuthenticated = true` y limpia errores.
  4. **Error HTTP 401 Unauthorized:** Confirma que el token ha expirado o es inválido en el servidor. Invoca `await _storageService.clearAll()`, fija `_isAuthenticated = false` y muestra aviso de expiración.
  5. **Error de red, timeout o servidor no disponible:** **Conserva intactos el token y los datos almacenados** (NO ejecuta `clearAll()`), evitando la destrucción de la sesión por problemas transitorios de conectividad. No declara autenticada la sesión hasta reanudar la comunicación con el backend.
  6. En el bloque `finally` actualiza `_isLoading = false` y `_isInitialized = true`, notificando a GoRouter para evaluar la navegación con el estado definitivo.
- **`iniciarSesion(email, password)`:** Gestiona el flujo de autenticación, activa el estado de carga y notifica a los oyentes.
- **`cerrarSesion()`:** Purga el almacenamiento y notifica el cambio a `isAuthenticated = false`.
- **Registro de Callback:** Se conecta directamente al `AuthInterceptor` para responder de inmediato ante expiraciones forzadas.

### 4.5 Enrutamiento con Guardianes (`frontend_flutter/lib/routes/app_router.dart`)
GoRouter implementa un sistema declarativo con guardianes de navegación reactivos:
- `refreshListenable: authController`: Escucha automáticamente los cambios del controlador.
- **Regla 1 (Guardia de protección):** Si el usuario NO está autenticado (`!isAuthenticated`) e intenta navegar a una ruta protegida (Dashboard `/`, listado `/productos`, detalle `/productos/:id`, creación `/productos/nuevo`), es redirigido inmediatamente a `/login`.
- **Regla 2 (Guardia de usuario autenticado):** Si el usuario YA está autenticado e intenta ingresar a `/login`, es redirigido automáticamente al Dashboard `/`.
- **Regla 3 (Prevención de saltos prematuros):** Durante `isLoading`, GoRouter no redirige hasta que finalice la verificación inicial de sesión.

### 4.6 Interfaz de Usuario y Experiencia (UX/UI)
1. **`LoginScreen` (`frontend_flutter/lib/screens/login_screen.dart`):**
   - Banner superior con degradado corporativo (`AppColors.primary` a `AppColors.primaryLight`).
   - Insignia visual *"Autenticación Segura JWT"*.
   - Campos de formulario con validación en tiempo real (correo válido, contraseña obligatoria).
   - Botón de alternancia para ver/ocultar contraseña con iconos accesibles.
   - Botón de acción con indicador de carga integrado (`CircularProgressIndicator`).
   - Manejo de errores con avisos visuales destacados en caso de credenciales incorrectas.
2. **`SessionInfoDialog` (`frontend_flutter/lib/widgets/session_info_dialog.dart`):**
   - Diálogo modal accesible desde el AppBar del Dashboard.
   - Muestra el nombre, correo y rol del usuario.
   - Insignia verde *"Sesión activa con JWT"*.
   - Aclaración explícita: *"Token resguardado en almacenamiento seguro (Keystore/Keychain). No accesible en texto plano."*
   - Botón destacado para cerrar sesión de forma segura.
3. **`DashboardScreen` (`frontend_flutter/lib/screens/dashboard_screen.dart`):**
   - Saludo dinámico: *"Hola, [Nombre del Usuario]"*.
   - Badge distintivo *"JWT ACTIVO"*.
   - Botón de perfil en la barra superior que abre la información de sesión.

---

## 5. MEDIDAS DE SEGURIDAD IMPLEMENTADAS

| Vulnerabilidad / Riesgo | Medida Implementada en Backend | Medida Implementada en Frontend |
| :--- | :--- | :--- |
| **Almacenamiento de contraseñas en texto plano** | Hashing con algoritmo bcrypt, sal dinámico y factor de costo adaptativo en `auth.py`. | La contraseña nunca se almacena en memoria persistente ni en caché local. |
| **Exposición de credenciales y secretos en Git** | `SECRET_KEY` y contraseñas gestionadas en `.env`, excluido en `.gitignore`. Se provee `.env.example`. | URL de la API gestionada en `.env`, excluida en `.gitignore`. |
| **Falsificación o manipulación de tokens** | Firma digital HMAC-SHA256 verificada criptográficamente en cada solicitud. | El token se envía intacto en el encabezado `Authorization: Bearer <token>`. |
| **Expiración y vigencia de sesiones** | Claim `exp` validado estrictamente en backend; captura de `ExpiredSignatureError`. | El interceptor captura HTTP 401, limpia la sesión y fuerza la navegación al login. |
| **Extracción del token en el cliente** | N/A (el servidor no almacena tokens, arquitectura stateless). | Almacenamiento exclusivo en `FlutterSecureStorage` (hardware Keystore/Keychain). Prohibido en SharedPreferences. |
| **Fuga de datos en registros (Logs)** | No se imprimen contraseñas, hashes ni tokens en consola ni en salidas estándar. | Logging de Dio configurado para sanitizar o suprimir tokens y cuerpos sensibles. |
| **Acceso no autorizado a rutas** | Inyección de dependencias `Depends(get_current_user)` en los 5 endpoints CRUD. | Guardianes reactivos de GoRouter impiden renderizar vistas protegidas sin sesión. |

---

## 6. RESULTADOS DE PRUEBAS AUTOMATIZADAS

### 6.1 Backend — Pytest (15/15 Pruebas Aprobadas)
Ejecución verificada mediante `backend/venv/Scripts/python.exe -m pytest -v backend/test_api.py`:

| # | Prueba | Propósito | Resultado |
| :---: | :--- | :--- | :---: |
| 1 | `test_1_listar_productos_iniciales` | Listado de catálogo con JWT | **PASSED** |
| 2 | `test_2_consultar_producto_existente` | Consulta por ID con JWT | **PASSED** |
| 3 | `test_3_consultar_producto_inexistente` | Retorno 404 Not Found con JWT | **PASSED** |
| 4 | `test_4_crear_producto_valido` | Creación de producto (201) con JWT | **PASSED** |
| 5 | `test_5_crear_producto_codigo_duplicado` | Validación de código único (400) | **PASSED** |
| 6 | `test_6_validaciones_precio_y_cantidad_invalidos` | Validación Pydantic v2 (422) | **PASSED** |
| 7 | `test_7_actualizar_producto_existente` | Actualización de producto (200) | **PASSED** |
| 8 | `test_8_actualizar_producto_inexistente` | Actualización ID no existente (404) | **PASSED** |
| 9 | `test_9_eliminar_producto_existente` | Eliminación de producto (200) | **PASSED** |
| 10 | `test_10_confirmar_producto_eliminado_no_aparece` | Verificación de eliminación física | **PASSED** |
| 11 | `test_11_persistencia_e_idempotencia_reinicio` | Verificación de persistencia SQLite | **PASSED** |
| 12 | `test_12_acceso_sin_token_rechazado_401` | Petición anónima rechazada con 401 | **PASSED** |
| 13 | `test_13_acceso_con_token_invalido_rechazado_401` | Token corrupto/falsificado rechazado con 401 | **PASSED** |
| 14 | `test_14_acceso_con_token_expirado_rechazado_401` | Token con fecha expirada rechazado con 401 | **PASSED** |
| 15 | `test_15_flujo_login_y_usuario_autenticado` | Login correcto e incorrecto y `/me` | **PASSED** |

**Resultado consolidado backend:** `15 passed, 2 warnings in 4.72s (100% de éxito)`.

---

### 6.2 Frontend — Flutter Tests y Análisis Estático (16/16 Pruebas Aprobadas)
Ejecución verificada mediante `flutter analyze` y `flutter test`:

#### Análisis Estático:
```powershell
flutter analyze
# Resultado: No issues found! (ran in 5.1s)
```

#### Suite Completa de Pruebas:
```powershell
flutter test
# Resultado: 00:03 +16: All tests passed!
```

**Desglose de pruebas en Flutter:**

| Archivo de Prueba | Caso de Prueba | Enfoque | Resultado |
| :--- | :--- | :--- | :---: |
| `auth_services_test.dart` | 1. Login exitoso almacena JWT y datos de usuario | Unitario | **PASSED** |
| `auth_services_test.dart` | 2. Login con credenciales erróneas lanza 401 | Unitario | **PASSED** |
| `auth_services_test.dart` | 3. getPerfil recupera usuario autenticado con JWT | Unitario | **PASSED** |
| `auth_services_test.dart` | 4. StorageService persiste y recupera token y metadatos | Unitario | **PASSED** |
| `auth_services_test.dart` | 5. StorageService clearAll elimina token y metadatos | Unitario | **PASSED** |
| `auth_services_test.dart` | 6. AuthInterceptor inyecta Bearer y captura 401 | Unitario | **PASSED** |
| `widget_test.dart` | 1. Renderizado de LoginScreen (banner, campos, botón) | Widget UI | **PASSED** |
| `widget_test.dart` | 2. Validaciones de formulario (campos requeridos y formato) | Widget UI | **PASSED** |
| `widget_test.dart` | 3. Alternancia de visibilidad de contraseña | Widget UI | **PASSED** |
| `widget_test.dart` | 4. Visualización de información en SessionInfoDialog | Widget UI | **PASSED** |
| `widget_test.dart` | 5. Carga inicial con sesión activa muestra saludo y badge | Widget UI | **PASSED** |
| `widget_test.dart` | 6. Cierre de sesión desde Dashboard redirige a Login | Widget UI | **PASSED** |
| `widget_test.dart` | 7. Métricas de Dashboard (KPIs calculados) | Widget UI | **PASSED** |
| `api_integration_test.dart` | 1. Flutter -> Backend real: listar productos con JWT | Integración Real | **PASSED** |
| `api_integration_test.dart` | 2. Flutter -> Backend real: consultar producto por ID | Integración Real | **PASSED** |
| `api_integration_test.dart` | 3. Flutter -> Backend real: ciclo completo CRUD | Integración Real | **PASSED** |

> **Nota de validación integral:** La suite completa de 16 pruebas automatizadas fue superada satisfactoriamente (16/16) y se encuentra plenamente alineada con la prueba manual en el emulador Android Pixel 8, ratificando el funcionamiento real de la persistencia y recuperación automática de sesión en hardware/emulador.

---

## 7. VALIDACIÓN DETALLADA DE LOS SIETE ESCENARIOS DOCENTES

Se presenta la matriz formal de validación técnica conforme a los requerimientos de evaluación del docente, integrando las evidencias automatizadas y los resultados de las pruebas manuales ejecutadas en el emulador Android Pixel 8 (**7 de 7 Escenarios Aprobados**):

### Escenario 1: Acceso anónimo a rutas protegidas
- **Procedimiento:** Realizar petición HTTP `GET /api/productos` sin la cabecera `Authorization` o intentar acceder a `/` en Flutter sin haber iniciado sesión.
- **Resultado Esperado:** 
  - Backend: Responder con código HTTP 401 Unauthorized y detalle descriptivo.
  - Flutter: El guardia de GoRouter intercepta la navegación y redirige de inmediato a la pantalla de `/login`.
- **Resultado Obtenido:** El backend rechazó la petición con código 401; GoRouter bloqueó la vista del Dashboard y presentó la pantalla de LoginScreen.
- **Evidencia Automatizada:**
  - Pytest: `test_12_acceso_sin_token_rechazado_401` (PASSED).
  - Flutter Test: `widget_test.dart` (Caso 1 de renderizado y redirección) (PASSED).
- **Pasos para Comprobación Manual en Emulador:**
  1. Instalar la aplicación en el emulador y asegurarse de no tener sesión iniciada.
  2. Abrir la aplicación.
  3. Comprobar que de inmediato se muestra la pantalla de inicio de sesión (`LoginScreen`) y que no es posible ver el Dashboard ni la lista de productos.
- **Estado:** **APROBADO**

---

### Escenario 2: Inicio de sesión con credenciales incorrectas
- **Procedimiento:** Enviar `POST /api/auth/login` con correo registrado pero contraseña incorrecta, o con usuario no registrado.
- **Resultado Esperado:**
  - Backend: Responder con HTTP 401 Unauthorized (`{"detail": "Credenciales inválidas. Verifique su correo y contraseña."}`).
  - Flutter: No almacenar ningún token, permanecer en `LoginScreen` y mostrar un mensaje visual de error claro.
- **Resultado Obtenido:** El backend devolvió HTTP 401; Flutter capturó el error, mantuvo al usuario en LoginScreen y desplegó el mensaje de advertencia.
- **Evidencia Automatizada:**
  - Pytest: `test_15_flujo_login_y_usuario_autenticado` (PASSED).
  - Flutter Test: `auth_services_test.dart` (Caso 2: login fallido) (PASSED).
- **Pasos para Comprobación Manual en Emulador:**
  1. En `LoginScreen`, escribir el correo `admin@inventario.com`.
  2. En la contraseña, escribir un valor deliberadamente erróneo (ej. `PasswordFalsa999`).
  3. Presionar el botón *"Iniciar Sesión"*.
  4. Observar que aparece el mensaje de error *"Credenciales inválidas"* en la parte inferior o en el diálogo, y que la pantalla no cambia de ruta.
- **Estado:** **APROBADO**

---

### Escenario 3: Inicio de sesión correcto
- **Procedimiento:** Enviar `POST /api/auth/login` con credenciales legítimas del administrador sembrado.
- **Resultado Esperado:**
  - Backend: Responder con HTTP 200 OK, entregando `access_token` JWT válido y el perfil del usuario.
  - Flutter: Guardar el token en almacenamiento seguro, guardar el nombre y correo en `SharedPreferences`, y redirigir reactivamente al Dashboard.
- **Resultado Obtenido:** El backend emitió el JWT con firma HS256 válida; GoRouter navegó exitosamente a la pantalla principal.
- **Evidencia Automatizada:**
  - Pytest: `test_15_flujo_login_y_usuario_autenticado` (PASSED).
  - Flutter Test: `auth_services_test.dart` (Caso 1: login exitoso) y `api_integration_test.dart` (setUpAll) (PASSED).
- **Pasos para Comprobación Manual en Emulador:**
  1. En `LoginScreen`, ingresar el correo y la contraseña configurados para el administrador (definidos en `backend/.env`).
  2. Presionar *"Iniciar Sesión"*.
  3. Verificar que la pantalla navega automáticamente al Dashboard.
  4. Observar que en el banner superior se visualiza: *"Hola, Administrador del Sistema"* y la insignia *"JWT ACTIVO"*.
- **Estado:** **APROBADO**

---

### Escenario 4: Operaciones CRUD con JWT
- **Procedimiento:** Una vez iniciada sesión, ejecutar las operaciones de consultar productos, ver detalle, crear un nuevo producto, actualizarlo y eliminarlo.
- **Resultado Esperado:** Cada petición enviada por Dio debe incorporar la cabecera `Authorization: Bearer <token>`. El backend debe validar la firma en cada endpoint y procesar la operación con códigos 200 o 201.
- **Resultado Obtenido:** Dio inyectó correctamente el encabezado Bearer en todas las llamadas; el backend procesó el listado, creación, edición y eliminación sin ningún error 401.
- **Evidencia Automatizada:**
  - Pytest: Tests 1 al 10 en `test_api.py` (ejecutados con cliente autenticado) (PASSED).
  - Flutter Test: `api_integration_test.dart` (ciclo completo real GET, POST, PUT, DELETE contra FastAPI) (PASSED).
- **Pasos para Comprobación Manual en Emulador:**
  1. Desde el Dashboard autenticado, presionar la tarjeta *"Total Productos"* o el botón flotante para ir al catálogo.
  2. Presionar el botón *"Nuevo Producto"* (`+`).
  3. Llenar los campos (ej. Nombre: `Mouse Gamer Pro`, Código: `MOU-990`, Precio: `150000`, Stock: `8`, Categoría: `Periféricos`) y presionar Guardar.
  4. Comprobar que el producto aparece en el catálogo.
  5. Editar el precio y guardarlo.
  6. Eliminar el producto creado y verificar que desaparece de la lista.
- **Estado:** **APROBADO**

---

### Escenario 5: Persistencia de sesión
- **Procedimiento (Prueba Manual en Emulador Android Pixel 8):**
  1. Se inició el backend FastAPI en la máquina anfitriona y se mantuvo activo durante toda la prueba.
  2. Se ejecutó la aplicación Flutter con la implementación corregida en el emulador Android Pixel 8.
  3. Se inició sesión correctamente con credenciales del administrador (`admin@inventario.com`) y se accedió al Dashboard, confirmando el saludo y el badge *"JWT ACTIVO"*.
  4. Se salió de la aplicación presionando el botón Home y se abrió la vista multitarea (aplicaciones recientes).
  5. Se cerró completamente la aplicación deslizando la tarjeta hacia arriba para forzar la terminación del proceso en memoria (*kill process*).
  6. Se volvió a abrir la aplicación pulsando su icono directamente desde el cajón de aplicaciones del emulador.
- **Resultado Esperado:**
  La aplicación debe leer el token JWT almacenado en `FlutterSecureStorage`, verificar la vigencia contra `GET /api/auth/me` en el backend y presentar directamente el Dashboard sin solicitar nuevamente el correo ni la contraseña.
- **Resultado Obtenido:**
  La aplicación recuperó automáticamente la sesión activa y mostró de forma directa el Dashboard principal con el catálogo cargado, el saludo *"Hola, Administrador del Sistema"* y la insignia *"JWT ACTIVO"*, **sin solicitar nuevamente las credenciales al usuario**.
- **Evidencia Técnica Disponible:**
  - **Prueba manual física:** Confirmada exitosamente en emulador Android Pixel 8.
  - **Trazas de depuración registradas:**
    ```
    [STORAGE] Token JWT recuperado exitosamente de almacenamiento seguro.
    [AUTH CONTROLLER] Token detectado en almacenamiento seguro. Validando vigencia con el servidor...
    [AUTH CONTROLLER] Sesión validada exitosamente por el servidor para: admin@inventario.com
    ```
  - **Pruebas automatizadas aprobadas:** `widget_test.dart` (Caso 5: Carga inicial con sesión activa) y `auth_services_test.dart` (Caso 4: Persistencia y recuperación en storage).
- **Estado:** **APROBADO**

---

### Escenario 6: Acceso a la API sin token
- **Procedimiento:** Ejecutar peticiones HTTP directas hacia cualquiera de los endpoints protegidos (`/api/productos`, `/api/productos/{id}`, `/api/auth/me`) omitiendo el encabezado `Authorization`.
- **Resultado Esperado:** El backend debe responder invariablemente con código HTTP 401 Unauthorized y el encabezado de respuesta `WWW-Authenticate: Bearer`.
- **Resultado Obtenido:** FastAPI interceptó la ausencia de credenciales mediante `OAuth2PasswordBearer` y retornó HTTP 401 con el mensaje *"No autenticado. Token de acceso requerido."*.
- **Evidencia Automatizada:**
  - Pytest: `test_12_acceso_sin_token_rechazado_401` y `test_13_acceso_con_token_invalido_rechazado_401` (PASSED).
  - Script de verificación de escenarios en servidor en vivo: Petición anónima retornó 401 Unauthorized (PASSED).
- **Pasos para Comprobación Manual (Terminal / cURL):**
  1. Abrir una terminal y ejecutar:
     ```bash
     curl -i -X GET http://127.0.0.1:8000/api/productos
     ```
  2. Observar la respuesta:
     ```http
     HTTP/1.1 401 Unauthorized
     WWW-Authenticate: Bearer
     {"detail":"No autenticado. Token de acceso requerido."}
     ```
- **Estado:** **APROBADO**

---

### Escenario 7: Cierre de sesión
- **Procedimiento:** Estando autenticado, pulsar la opción de cierre de sesión desde la aplicación móvil.
- **Resultado Esperado:** 
  - `StorageService` debe eliminar el token de `FlutterSecureStorage` y los metadatos de `SharedPreferences`.
  - El estado debe transicionar a `isAuthenticated = false`.
  - GoRouter debe redirigir inmediatamente a `/login`.
  - El botón "Atrás" de Android no debe permitir volver al Dashboard.
  - Futuras peticiones de red deben carecer de token.
- **Resultado Obtenido:** El almacenamiento local fue purgado; el `refreshListenable` de GoRouter detectó el cambio de estado y bloqueó el acceso al Dashboard, redirigiendo a la pantalla de login.
- **Evidencia Automatizada:**
  - Flutter Test: `widget_test.dart` (Caso 6: Cierre de sesión desde Dashboard redirige a LoginScreen) y `auth_services_test.dart` (Caso 5: clearAll) (PASSED).
- **Pasos para Comprobación Manual en Emulador:**
  1. En el Dashboard autenticado, presionar el icono de perfil en la esquina superior derecha del AppBar.
  2. En el diálogo emergente `SessionInfoDialog`, presionar el botón rojo *"Cerrar Sesión"*.
  3. Confirmar que la aplicación navega de inmediato a `LoginScreen`.
  4. Presionar el botón físico o gesto de *"Atrás"* del emulador Android.
  5. Comprobar que la app se minimiza o cierra, pero en ningún momento permite volver a ver el Dashboard protegido.
- **Estado:** **APROBADO**

---

## 8. LIMITACIONES CONOCIDAS Y RECOMENDACIONES DE OPERACIÓN

1. **Resolución y Validación de la Persistencia de Sesión en Android (Escenario 5):**
   - El fallo de recuperación de sesión en arranque en frío (*cold start*) fue corregido mediante la adopción de las opciones estándar de `FlutterSecureStorage` en Android (`AndroidOptions(encryptedSharedPreferences: false, resetOnError: false)`), la unificación de la instancia de `StorageService` mediante el patrón Factory en `AuthController`, y la protección del almacenamiento para que únicamente se purgue ante errores HTTP 401 confirmados por el backend.
   - El comportamiento fue validado satisfactoriamente en el emulador Android Pixel 8, confirmando que la sesión se mantiene activa de forma permanente tras matar y reabrir la aplicación.
2. **Pruebas en Emulador vs. Entorno Local:**
   - Para que el emulador Android se comunique con el backend FastAPI que corre en la máquina anfitriona (Windows), es indispensable configurar en `frontend_flutter/.env`:
     `API_BASE_URL=http://10.0.2.2:8000/api`
   - Si se ejecuta Flutter para Windows Desktop o Web, se debe utilizar:
     `API_BASE_URL=http://127.0.0.1:8000/api`
   - El servidor Uvicorn debe iniciarse con `--host 0.0.0.0` para admitir tráfico desde `10.0.2.2` o dispositivos en red local.
3. **Revocación de Tokens en el Servidor (Blacklist / Refresh Tokens):**
   - La arquitectura actual implementa tokens de acceso firmados con expiración fija (60 minutos por defecto). Al tratarse de un diseño *stateless*, el cierre de sesión destruye el token en el cliente.
   - En entornos de producción empresarial con requisitos bancarios, se recomienda implementar una lista de revocación en Redis o una arquitectura de *Refresh Tokens* rotativos almacenados en base de datos.
4. **Plataformas de Escritorio en Desarrollo (Linux/Windows):**
   - El plugin `flutter_secure_storage` en entornos Windows/Linux de desarrollo utiliza interfaces locales seguras (Data Protection API en Windows / libsecret en Linux). En pruebas unitarias se verificó bajo mocks, pero en entornos de producción debe configurarse según las particularidades de cada sistema operativo.

---

## 9. GUÍA DE EJECUCIÓN PASO A PASO

Para reproducir la ejecución completa del sistema con autenticación JWT, siga estos pasos:

### Paso 1: Configurar Variables de Entorno

#### Backend:
1. En `backend/`, si no existe `.env`, copiar la plantilla `.env.example`:
   ```powershell
   Copy-Item backend\.env.example backend\.env
   ```
2. Generar una clave secreta segura:
   ```powershell
   backend\venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(32))"
   ```
3. Editar `backend/.env` y asignar la `SECRET_KEY` generada, así como las credenciales iniciales deseadas para el administrador (`SEED_ADMIN_EMAIL` y `SEED_ADMIN_PASSWORD`).

#### Frontend:
1. En `frontend_flutter/`, si no existe `.env`, copiar la plantilla `.env.example`:
   ```powershell
   Copy-Item frontend_flutter\.env.example frontend_flutter\.env
   ```
2. Ajustar la URL según el destino de ejecución (usar `10.0.2.2:8000/api` para emulador Android o `127.0.0.1:8000/api` para Windows Desktop).

---

### Paso 2: Iniciar el Servidor Backend (FastAPI)
Abrir una terminal en el directorio raíz:
```powershell
cd C:\proyectos_moviles\inventario_parcial_flutter\backend
.\venv\Scripts\Activate.ps1
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
*El servidor iniciará en `http://0.0.0.0:8000`. Al arrancar, sembrará automáticamente el usuario administrador y los 12 productos iniciales si no existen.*

---

### Paso 3: Ejecución de Pruebas Automatizadas
Para verificar la integridad del código:

```powershell
# Pruebas del Backend (15 pruebas):
backend\venv\Scripts\python.exe -m pytest -v backend/test_api.py

# Análisis Estático de Flutter (0 problemas):
cd frontend_flutter
flutter analyze

# Pruebas de Flutter (16 pruebas, incluyendo integración real contra FastAPI):
flutter test
```

---

### Paso 4: Iniciar la Aplicación Móvil en Emulador
En una segunda terminal:
```powershell
cd C:\proyectos_moviles\inventario_parcial_flutter\frontend_flutter
flutter run
```
*Seleccionar el emulador Android activo (ej. `Pixel 8` o `emulator-5554`).*

---

## 10. CONCLUSIONES DE INGENIERÍA DE SOFTWARE

1. **Robustez y Desacoplamiento:** La adopción del estándar JWT (RFC 7519) permitió proteger completamente los recursos del inventario sin introducir acoplamiento de estado en el servidor FastAPI. El backend se mantiene escalable, seguro y sin sesiones en memoria, validando correctamente firmas y expiración en cada endpoint CRUD.
2. **Defensa en Profundidad y Persistencia Confiable:** La arquitectura de almacenamiento segregado demostró su eficacia al utilizar el hardware seguro de Android (Android Keystore con cifrado estándar RSA/AES) para resguardar el JWT de forma aislada, superando las limitaciones de librerías criptográficas experimentales y garantizando la persistencia entre ciclos de vida completos del proceso móvil.
3. **Mantenibilidad Mediante Interceptores:** Centralizar la inyección de credenciales y la captura de errores 401 en `AuthInterceptor` evitó duplicar código en los controladores de producto y garantizó que cualquier expiración o rechazo de sesión se gestione de forma reactiva hacia el flujo de inicio de sesión.
4. **Cumplimiento Integral de Objetivos (100% Validado):** El proyecto culmina con un nivel de madurez técnica óptimo: 15/15 pruebas backend aprobadas en pytest, 16/16 pruebas Flutter aprobadas con 0 observaciones en análisis estático, y **7 de 7 escenarios docentes formalmente aprobados** tanto analíticamente como mediante validación física en el emulador Android Pixel 8, confirmando un sistema de gestión comercial seguro, responsivo y completamente funcional.
