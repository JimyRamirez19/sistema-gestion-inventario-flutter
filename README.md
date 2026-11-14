# Sistema de Gestión de Inventario — API REST + Flutter con Autenticación JWT

**Asignatura:** Electiva Profesional I - Desarrollo de Aplicaciones Móviles  
**Evaluación:** Proyecto Integral — Segundo Parcial Práctico + Taller de Autenticación JWT  
**Semestre:** 2026-2  
**Tecnologías:** Python 3.14 | FastAPI | SQLAlchemy | SQLite | PyJWT | Passlib (bcrypt) | Flutter 3.47 (Dart 3.13) | Dio | GoRouter | flutter_secure_storage | shared_preferences | flutter_dotenv  
**Rama de Desarrollo:** `feature/taller_jwt`  
**Repositorio Oficial:** [sistema-gestion-inventario-flutter](https://github.com/JimyRamirez19/sistema-gestion-inventario-flutter)  

---

## 1. Descripción del Proyecto

El **Sistema de Gestión de Inventario** es una solución de software cliente-servidor completa y desacoplada, diseñada para la administración comercial de productos, métricas de inventario y control de acceso seguro mediante **JSON Web Tokens (JWT)**.

El sistema garantiza que todas las operaciones de consulta de catálogo, detalle de producto y mutaciones de datos (crear, actualizar, eliminar) estén estrictamente protegidas bajo estándares de la industria:
1. **Backend RESTful (FastAPI):** Proporciona servicios sin estado (*stateless*), validación estricta de esquemas con **Pydantic v2**, almacenamiento persistente en **SQLite**, contraseñas cifradas con **bcrypt** y firma/validación simétrica de tokens con **PyJWT**.
2. **Aplicación Móvil (Flutter):** Diseñada bajo **Material 3**, implementa enrutamiento declarativo y protegido con **GoRouter**, cliente HTTP centralizado con **Dio**, inyección automática de credenciales con **AuthInterceptor**, almacenamiento criptográfico en hardware con **flutter_secure_storage** y cálculo de indicadores comerciales en tiempo real.

---

## 2. Tecnologías Utilizadas

### Backend
- **Python 3.14.3:** Entorno de ejecución base.
- **FastAPI 0.115+:** Framework web moderno y asíncrono para la construcción de APIs REST de alto rendimiento.
- **Uvicorn:** Servidor ASGI para ejecución de la API en producción y desarrollo.
- **SQLAlchemy 2.0+:** ORM para el mapeo objeto-relacional y consultas a la base de datos.
- **SQLite:** Motor de base de datos relacional ligero y persistente en archivo físico (`inventario.db`).
- **Pydantic v2:** Validación estricta de tipos de datos, serialización y esquemas de entrada/salida.
- **PyJWT 2.10+:** Generación, firma digital (algoritmo HS256) y decodificación/verificación de tokens JWT.
- **Passlib (bcrypt) 1.7+:** Algoritmo de derivación de claves para hashing seguro de contraseñas con sal dinámica.
- **Python-dotenv:** Carga de variables de entorno desde archivos `.env`.
- **Pytest + HTTPX:** Framework para pruebas automatizadas de endpoints.

### Frontend (Flutter)
- **Flutter 3.47 / Dart 3.13:** SDK móvil multiplataforma.
- **Material 3:** Sistema de diseño visual corporativo con tema personalizado (`AppColors`, `AppTheme`).
- **Dio 5.8+:** Cliente HTTP robusto con interceptores para inyección de tokens y manejo centralizado de respuestas HTTP 401.
- **GoRouter 18.1+:** Enrutador declarativo con guardianes de navegación reactivos (`redirect` guards).
- **flutter_secure_storage 9.2+:** Almacenamiento seguro en hardware (Android Keystore / iOS Keychain) para el token JWT.
- **shared_preferences 2.3+:** Almacenamiento local ligero para metadatos no sensibles del usuario (nombre, correo).
- **flutter_dotenv 6.0+:** Gestión de variables de entorno locales en el dispositivo móvil.
- **Intl:** Formateo monetario y numérico en pesos colombianos (COP).

---

## 3. Arquitectura General del Sistema

La solución opera bajo un modelo desacoplado donde el cliente móvil y el servidor backend interactúan exclusivamente a través del protocolo HTTP/HTTPS utilizando el estándar JWT (RFC 7519):

```
+-----------------------------------------------------------------------------------+
|                            ARQUITECTURA CLIENTE - SERVIDOR                        |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|  [ CLIENTE FLUTTER ]                                                              |
|    |                                                                              |
|    +--> UI Screens: LoginScreen <---> DashboardScreen <---> Productos CRUD        |
|    |           ^                            ^                                     |
|    |           |                            |                                     |
|    +--> AuthController (ChangeNotifier) ---> Escucha estado y notifica a GoRouter |
|    |           |                                                                  |
|    |           v                                                                  |
|    +--> StorageService:                                                           |
|    |       * flutter_secure_storage -> [ Almacén Seguro: JWT ]                    |
|    |       * shared_preferences    -> [ Metadatos: Nombre, Email ]                |
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
|  [ SERVIDOR FASTAPI ]                                                             |
|    |                                                                              |
|    +--> Middlewares: CORS (Cross-Origin Resource Sharing)                         |
|    |                                                                              |
|    +--> Endpoints de Autenticación:                                               |
|    |       * POST /api/auth/login -> Valida bcrypt, emite JWT HS256               |
|    |       * GET  /api/auth/me    -> Requiere get_current_user (valida token)     |
|    |                                                                              |
|    +--> Endpoints Protegidos CRUD:                                                |
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

## 4. Estructura del Proyecto

```
inventario_parcial_flutter/
|-- .gitignore                            # Reglas de exclusión (oculta .env, venv, db, build)
|-- README.md                             # Documentación técnica general y guía de ejecución
|-- INFORME_FINAL_JWT.md                  # Informe académico formal de entrega del taller JWT
|-- docs/
|   `-- screenshots/                      # Evidencias gráficas del emulador en ejecución
|-- backend/                              # Servidor API RESTful (FastAPI)
|   |-- .env                              # Variables locales y secretos (IGNORADO EN GIT)
|   |-- .env.example                      # Plantilla de referencia para configuración segura
|   |-- requirements.txt                  # Dependencias de Python
|   |-- database.py                       # Conexión SQLite y generador de sesiones SQLAlchemy
|   |-- models.py                         # Modelos ORM: 'Producto' y 'Usuario'
|   |-- schemas.py                        # Esquemas Pydantic v2 para validación y serialización
|   |-- auth.py                           # Criptografía: hashing bcrypt, creación y validación JWT
|   |-- crud.py                           # Operaciones de persistencia para productos y usuarios
|   |-- seed_data.py                      # Siembra inicial idempotente de admin y 12 productos
|   |-- main.py                           # Aplicación FastAPI, CORS, rutas y ciclo de vida lifespan
|   |-- inventario.db                     # Base de datos física persistente SQLite
|   `-- test_api.py                       # Suite de 15 pruebas automatizadas con pytest
`-- frontend_flutter/                     # Aplicación Móvil (Flutter)
    |-- .env                              # Configuración local de URL (IGNORADO EN GIT)
    |-- .env.example                      # Plantilla de URL para emulador y entornos locales
    |-- pubspec.yaml                      # Dependencias de Flutter y assets declarados
    |-- test/
    |   |-- auth_services_test.dart       # Pruebas unitarias de StorageService, AuthService e Interceptor
    |   |-- widget_test.dart              # Pruebas de widgets: LoginScreen, SessionDialog, Dashboard
    |   `-- api_integration_test.dart     # Pruebas de integración HTTP real Flutter -> FastAPI
    `-- lib/
        |-- main.dart                     # Inicialización de widgets, carga de .env y arranque
        |-- app.dart                      # Configuración de MaterialApp.router y tema visual
        |-- core/
        |   |-- constants/                # Constantes de rutas API y paleta de colores comercial
        |   |-- errors/                   # Excepciones personalizadas (ApiException)
        |   |-- network/                  # Cliente HTTP Dio y AuthInterceptor
        |   |-- theme/                    # Tema global Material 3
        |   `-- utils/                    # Formateadores monetarios y numéricos
        |-- models/                       # Modelos Dart: Producto y Usuario
        |-- services/                     # Servicios: ProductoService, AuthService, StorageService
        |-- controllers/                  # InventarioController y AuthController
        |-- routes/                       # Enrutador GoRouter con guardianes de navegación
        |-- screens/
        |   |-- login_screen.dart         # Pantalla de inicio de sesión con diseño definitivo
        |   |-- dashboard_screen.dart     # Dashboard con KPIs, saludo de usuario y badge JWT
        |   |-- productos_list_screen.dart# Catálogo con buscador, filtros y tarjetas de producto
        |   |-- producto_detail_screen.dart# Vista detallada de especificaciones y acciones
        |   `-- producto_form_screen.dart # Formulario unificado de Creación y Edición
        `-- widgets/                      # Componentes reutilizables (SessionInfoDialog, MetricCard, etc.)
```

---

## 5. Requisitos de Instalación

Antes de iniciar, asegúrese de tener instalado en su sistema operativo:
- **Python:** Versión 3.14.x (o compatible 3.10+).
- **Flutter SDK:** Versión 3.47.x (canal estable, con Dart 3.13+).
- **Git:** Para control de versiones.
- **Android Studio / SDK:** Con un dispositivo virtual (AVD) configurado para emulación.
- **Editor de Código:** Visual Studio Code o Android Studio con plugins de Flutter y Python.

---

## 6. Configuración Segura del Archivo `.env`

Por estrictos principios de seguridad de la información, los archivos `.env` reales que contienen claves criptográficas y credenciales **están excluidos del repositorio mediante `.gitignore`**.

### 6.1 Configuración del Backend (`backend/.env`)
Copie el archivo de ejemplo a su archivo `.env` local:
```powershell
Copy-Item backend\.env.example backend\.env
```

Genere una clave secreta aleatoria criptográficamente segura ejecutando:
```powershell
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Configure en `backend/.env` las siguientes variables (ajustando sus propios valores de desarrollo):
```env
# Clave simétrica para firmar y verificar tokens JWT
SECRET_KEY=su_clave_secreta_aleatoria_generada_aqui

# Algoritmo de firma
ALGORITHM=HS256

# Tiempo de vigencia del token en minutos
ACCESS_TOKEN_EXPIRE_MINUTES=60

# Credenciales para la creación inicial idempotente del usuario administrador
SEED_ADMIN_NAME=Administrador del Sistema
SEED_ADMIN_EMAIL=admin@inventario.com
SEED_ADMIN_PASSWORD=ConfigureAquiSuContrasenaSegura2026*
```

### 6.2 Configuración de Flutter (`frontend_flutter/.env`)
Copie el archivo de ejemplo a su archivo `.env` local:
```powershell
Copy-Item frontend_flutter\.env.example frontend_flutter\.env
```

Ajuste la variable `API_BASE_URL` según la plataforma donde ejecutará la app (ver sección 10):
```env
# Para Emulador Android en Android Studio:
API_BASE_URL=http://10.0.2.2:8000/api

# Para Windows Desktop / Navegador Web:
# API_BASE_URL=http://127.0.0.1:8000/api
```

---

## 7. Instalación de Dependencias del Backend

1. Abra una terminal en la carpeta del backend:
   ```powershell
   cd C:\proyectos_moviles\inventario_parcial_flutter\backend
   ```
2. Cree y active un entorno virtual de Python:
   ```powershell
   python -m venv venv
   .\venv\Scripts\Activate.ps1
   ```
3. Instale las dependencias especificadas en `requirements.txt`:
   ```powershell
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

---

## 8. Ejecución del Servidor Backend (FastAPI)

Con el entorno virtual activado, inicie el servidor de desarrollo Uvicorn:

```powershell
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

> **Nota sobre el parámetro `--host 0.0.0.0`:** Es obligatorio para que el servidor escuche en todas las interfaces de red, permitiendo que el emulador Android (`10.0.2.2:8000`) o dispositivos físicos en la red local puedan comunicarse con la API.

Al arrancar, el servidor ejecutará el evento `lifespan`:
- Creará las tablas en `inventario.db` si no existen.
- Sembrará automáticamente al usuario administrador si aún no ha sido registrado.
- Sembrará el catálogo comercial de 12 productos iniciales si la tabla está vacía.

### Documentación Interactiva de la API
Una vez activo el servidor, puede consultar y probar los endpoints en:
- **Swagger UI:** `http://localhost:8000/docs`
- **ReDoc:** `http://localhost:8000/redoc`

---

## 9. Ejecución de la Aplicación Flutter

1. Abra una segunda terminal y navegue a la carpeta de Flutter:
   ```powershell
   cd C:\proyectos_moviles\inventario_parcial_flutter\frontend_flutter
   ```
2. Descargue las dependencias del proyecto:
   ```powershell
   flutter pub get
   ```
3. Inicie el emulador de Android desde Android Studio o mediante el comando de Flutter:
   ```powershell
   flutter emulators --launch <nombre_emulador>
   ```
4. Ejecute la aplicación móvil:
   ```powershell
   flutter run
   ```
   *(Si tiene múltiples dispositivos conectados, puede especificar el ID del emulador: `flutter run -d emulator-5554`)*.

---

## 10. Configuración de URL según el Entorno de Ejecución

Es fundamental configurar la dirección IP adecuada en `frontend_flutter/.env` para permitir la comunicación de red con el backend FastAPI:

| Entorno de Prueba | Dirección Requerida en `frontend_flutter/.env` | Explicación Técnica |
| :--- | :--- | :--- |
| **Emulador Android** | `API_BASE_URL=http://10.0.2.2:8000/api` | En el emulador de Android Studio, la dirección de bucle invertido (`localhost` / `127.0.0.1`) apunta al propio emulador. La IP especial `10.0.2.2` es el alias que el router virtual de Android asigna a la máquina anfitriona (su PC). |
| **Windows Desktop** | `API_BASE_URL=http://127.0.0.1:8000/api` | La aplicación de escritorio se ejecuta en el mismo host que el servidor FastAPI, por lo que `127.0.0.1` o `localhost` funcionan de manera directa. |
| **Google Chrome (Web)** | `API_BASE_URL=http://127.0.0.1:8000/api` | El navegador ejecuta la app en la misma máquina. El backend ya cuenta con middleware CORS habilitado para admitir llamadas desde cualquier origen. |
| **Dispositivo Móvil Físico** | `API_BASE_URL=http://<IP_LOCAL_PC>:8000/api` | Si conecta su celular por Wi-Fi o USB, debe reemplazar `<IP_LOCAL_PC>` por la dirección IPv4 local de su computadora (ej. `http://192.168.1.15:8000/api`). |

---

## 11. Flujo de Inicio de Sesión y Gestión de Usuarios

1. **Pantalla de Inicio de Sesión (`LoginScreen`):**
   - Al abrir la aplicación por primera vez, el guardián de rutas detecta que no hay una sesión activa y redirige al usuario a `/login`.
   - Ingrese el correo del administrador (configurado en `SEED_ADMIN_EMAIL`) y la contraseña correspondiente (configurada en `SEED_ADMIN_PASSWORD`).
   - La pantalla cuenta con validaciones automáticas: correo con formato válido y contraseña obligatoria.
   - Dispone de un botón con icono para mostrar u ocultar la contraseña.
2. **Autenticación y Redirección:**
   - Al pulsar *"Iniciar Sesión"*, se activa un indicador de carga circular.
   - Si las credenciales son incorrectas, se muestra un mensaje de error claro en pantalla sin filtrar detalles del sistema.
   - Si las credenciales son válidas, el backend entrega el token JWT y los datos del usuario.
   - El token se guarda en el almacén seguro (`FlutterSecureStorage`) y la aplicación navega de inmediato al **Dashboard**.
3. **Experiencia en el Dashboard:**
   - La cabecera saluda al usuario por su nombre (*"Hola, Administrador del Sistema"*).
   - Se visualiza una insignia distintiva verde *"JWT ACTIVO"*.
   - Todas las métricas (Total Productos, Valor del Inventario, Stock Bajo) y la lista de productos se consultan con el token Bearer adjunto.
4. **Información de Sesión y Cierre de Sesión:**
   - En la esquina superior derecha del AppBar se encuentra el botón de perfil.
   - Al presionarlo, se abre el diálogo modal `SessionInfoDialog`, que muestra:
     - Nombre y correo del usuario autenticado.
     - Estado de sesión: *"Sesión activa con JWT"*.
     - Indicador informativo de seguridad: *"Token resguardado en almacenamiento seguro (Keystore/Keychain). No accesible en texto plano."*
     - Botón rojo de *"Cerrar Sesión"*.
   - Al cerrar sesión, se purgan inmediatamente los datos locales y la aplicación redirige de forma forzosa a la pantalla de login, bloqueando el retorno mediante el botón atrás de Android.

---

## 12. Arquitectura y Funcionamiento de los JSON Web Tokens (JWT)

El sistema implementa el estándar abierto **RFC 7519** para autenticación basada en tokens sin estado (*stateless*):

1. **Estructura del Token emitido:**
   - **Header:** Define el tipo de token (`JWT`) y el algoritmo criptográfico (`HS256`).
   - **Payload (Claims):**
     - `sub`: Identificador del sujeto (correo del usuario: `admin@inventario.com`).
     - `exp`: Timestamp Unix de expiración (por defecto actual + 60 minutos).
   - **Signature:** Firma digital HMAC generada a partir de `HMACSHA256(base64UrlEncode(Header) + "." + base64UrlEncode(Payload), SECRET_KEY)`.
2. **Ciclo de Vida en el Cliente:**
   - **Almacenamiento:** El token se almacena en `FlutterSecureStorage`, garantizando que quede cifrado mediante Android Keystore o iOS Keychain. **Está estrictamente prohibido guardar el JWT en SharedPreferences.**
   - **Transmisión:** En cada petición HTTP enviada por Dio, el `AuthInterceptor` extrae el token y agrega la cabecera:
     ```http
     Authorization: Bearer <token_jwt>
     ```
3. **Validación en el Servidor:**
   - En cada ruta protegida, la dependencia `get_current_user` intercepta el token, verifica la validez matemática de la firma con la clave simétrica `SECRET_KEY` y revisa que `exp > timestamp_actual`.
   - Si el token expiró, responde `401 Unauthorized` (`detail: "El token de autenticación ha expirado."`).
   - Si el token fue manipulado, responde `401 Unauthorized` (`detail: "Token de autenticación inválido."`).
4. **Respuesta Reactiva del Cliente:**
   - Si el servidor retorna HTTP 401 en cualquier ruta de producto, el `AuthInterceptor` captura el código de estado, invoca el callback `onSessionExpired()`, purga el almacenamiento local y GoRouter redirige al usuario al inicio de sesión.

---

## 13. Guía de Ejecución de Pruebas Automatizadas

El proyecto cuenta con una cobertura integral de pruebas que valida el 100% de los componentes implementados:

### 13.1 Pruebas del Backend (Pytest)
Asegúrese de tener activado el entorno virtual en `backend/` y ejecute:

```powershell
python -m pytest -v backend/test_api.py
```

**Resultado esperado:**
```
======================= 15 passed, 2 warnings in 6.81s ========================
```
*Las 15 pruebas verifican el catálogo inicial, detalle, errores 404, creación, validación de códigos únicos duplicados, validaciones de Pydantic v2 (precio y stock no negativos), actualización, eliminación, persistencia en reinicio, rechazo de peticiones anónimas (401), rechazo de tokens inválidos (401), rechazo de tokens expirados (401) y flujo completo de login con emisión de JWT.*

### 13.2 Análisis Estático de Flutter
En la carpeta `frontend_flutter/`:

```powershell
flutter analyze
```

**Resultado esperado:**
```
Analyzing frontend_flutter...
No issues found! (ran in 5.1s)
```

### 13.3 Suite de Pruebas de Flutter (Unitarias, Widgets e Integración Real)
Para ejecutar las 16 pruebas automatizadas de Flutter:
> **Importante:** Asegúrese de que el backend FastAPI esté ejecutándose en `http://127.0.0.1:8000` para que las pruebas de integración real con el servidor puedan conectarse y autenticarse.

```powershell
flutter test
```

**Resultado esperado:**
```
00:03 +16: All tests passed!
```
*Incluye:*
- `auth_services_test.dart` (6 pruebas unitarias: login, manejo de 401, getPerfil, StorageService seguro, clearAll, e interceptor de Dio).
- `widget_test.dart` (7 pruebas de UI: renderizado de LoginScreen, validaciones de formulario, visibilidad de contraseña, diálogo de sesión, carga con sesión activa, redirección por cierre de sesión y KPIs del Dashboard).
- `api_integration_test.dart` (3 pruebas de integración HTTP real: login y obtención de JWT, listar productos autenticado, consultar por ID autenticado y ciclo CRUD completo crear-editar-eliminar contra FastAPI).

---

## 14. Matriz de Validación de los Siete Escenarios Docentes

A continuación se resume el estado de cumplimiento y validación de cada uno de los 7 escenarios requeridos para la evaluación del taller:

| # | Escenario Evaluado | Resultado Esperado | Evidencia Automatizada | Validación Manual en Emulador | Estado |
| :-: | :--- | :--- | :--- | :--- | :-: |
| **1** | **Acceso anónimo a rutas protegidas** | Peticiones HTTP sin token devuelven HTTP 401. En Flutter, navegación anónima a Dashboard redirige a `/login`. | Pytest: `test_12_acceso_sin_token_rechazado_401`. Flutter: `widget_test.dart`. | Al abrir la app sin sesión previa, GoRouter muestra inmediatamente la pantalla de Login y bloquea el Dashboard. | **APROBADO** |
| **2** | **Inicio de sesión con credenciales incorrectas** | El backend responde HTTP 401 (`detail: "Credenciales inválidas..."`). Flutter permanece en Login y muestra aviso de error. | Pytest: `test_15_flujo_login_y_usuario_autenticado`. Flutter: `auth_services_test.dart`. | Ingresar contraseña errónea en el emulador; la app permanece en Login y muestra aviso en rojo sin navegar. | **APROBADO** |
| **3** | **Inicio de sesión correcto** | Backend emite JWT firmado (HS256). Flutter guarda token en almacenamiento seguro y redirige al Dashboard. | Pytest: `test_15_flujo_login_y_usuario_autenticado`. Flutter: `api_integration_test.dart`. | Ingresar credenciales del admin; navega al Dashboard, saluda con el nombre y exhibe badge *"JWT ACTIVO"*. | **APROBADO** |
| **4** | **Operaciones CRUD con JWT** | Las 5 operaciones (listar, detalle, crear, editar, eliminar) inyectan `Authorization: Bearer <token>` y responden 200/201. | Pytest: Tests 1 al 10 en `test_api.py`. Flutter: `api_integration_test.dart` (ciclo completo). | En el emulador, crear un nuevo producto, consultarlo, editar su precio y eliminarlo sin recibir errores de autorización. | **APROBADO** |
| **5** | **Persistencia de sesión** | Al cerrar y reabrir la app, el token seguro se recupera y se permite el ingreso directo al Dashboard sin pedir login. | Flutter Test: `widget_test.dart` (Caso 5: Carga inicial activa) y `auth_services_test.dart`. | Cerrar la app en el emulador (deslizar en multitarea para matar el proceso) y volver a abrirla; entra directo al Dashboard. | **APROBADO** |
| **6** | **Acceso a la API sin token** | Petición externa directa (cURL/Postman) a cualquier ruta `/api/productos` devuelve HTTP 401 con `WWW-Authenticate: Bearer`. | Pytest: `test_12_acceso_sin_token_rechazado_401`. Verificación en servidor en vivo. | Ejecutar `curl -i http://127.0.0.1:8000/api/productos` desde la terminal; responde HTTP 401 Unauthorized. | **APROBADO** |
| **7** | **Cierre de sesión** | Se eliminan el token y los datos locales de sesión. GoRouter redirige de inmediato al login y bloquea el botón atrás. | Flutter Test: `widget_test.dart` (Caso 6: Cierre de sesión) y `auth_services_test.dart`. | Tocar icono de perfil en el AppBar del emulador, pulsar *"Cerrar Sesión"*; regresa a Login y botón atrás no vuelve al Dashboard. | **APROBADO** |

> Para un análisis técnico exhaustivo de cada escenario, detalles de seguridad y consideraciones de arquitectura, consulte el documento adjunto: [INFORME_FINAL_JWT.md](INFORME_FINAL_JWT.md).
