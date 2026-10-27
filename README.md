# Sistema de Gestion de Inventario con API REST y Flutter

**Asignatura:** Electiva Profesional I - Desarrollo de Aplicaciones Moviles  
**Evaluacion:** Segundo Parcial Practico  
**Semestre:** 2026-2  
**Tecnologias:** Python 3.14 | FastAPI | SQLAlchemy | SQLite | Flutter 3.47 (Dart 3.13) | Dio | go_router | flutter_dotenv

---

## 1. Descripcion del Proyecto

El **Sistema de Gestion de Inventario** es una solucion de software completa para la administracion comercial de productos. Consta de una arquitectura desacoplada cliente-servidor con:

1. **Backend API RESTful propia:** Desarrollada con **FastAPI** y **SQLAlchemy**, garantizando validacion estricta de esquemas con **Pydantic v2** y persistencia real en archivo fisico **SQLite** (`inventario.db`).
2. **Aplicacion Movil Flutter:** Disenada bajo **Material 3** con una paleta profesional para comercio y tecnologia. Consume la API mediante el cliente HTTP **Dio**, navega con rutas parametrizadas con **go_router**, gestiona variables de entorno con **flutter_dotenv** y proporciona indicadores reactivos (KPIs) en tiempo real calculados sobre datos reales.

---

## 2. Arquitectura de la Solucion

```
inventario_parcial_flutter/
|-- .gitignore                      # Reglas de exclusion para Git (oculta venv, build, .env)
|-- README.md                       # Documentacion tecnica completa y guia de ejecucion
|-- docs/
|   `-- screenshots/                # Evidencias graficas del emulador en ejecucion
|-- backend/                        # Backend API REST
|   |-- venv/                       # Entorno virtual de Python
|   |-- requirements.txt            # Dependencias del backend
|   |-- database.py                 # Conexion SQLite con SQLAlchemy (SessionLocal, get_db)
|   |-- models.py                   # Entidad SQLAlchemy 'Producto' con CheckConstraints
|   |-- schemas.py                  # Esquemas Pydantic v2 (Base, Create, Update, Response)
|   |-- crud.py                     # Operaciones de persistencia y manejo de IntegrityError
|   |-- seed_data.py                # 12 productos comerciales iniciales (idempotente)
|   |-- main.py                     # Aplicacion FastAPI, CORS, rutas y ciclo de vida lifespan
|   |-- inventario.db               # Base de datos fisica persistente SQLite
|   `-- test_api.py                 # 11 pruebas automatizadas de endpoints con pytest
`-- frontend_flutter/               # Aplicacion movil Flutter
    |-- .env                        # Variables locales (API_BASE_URL)
    |-- .env.example                # Plantilla de entorno para otros desarrolladores
    |-- pubspec.yaml                # Dependencias (dio, go_router, flutter_dotenv, intl)
    |-- android/                    # Configuracion Android (permiso INTERNET y cleartextTraffic)
    |-- test/
    |   |-- widget_test.dart        # Prueba de widget y modelos
    |   `-- api_integration_test.dart # Pruebas de integracion reales Flutter -> Backend
    `-- lib/
        |-- main.dart               # Inicializacion de Flutter, carga de .env y arranque
        |-- app.dart                # MaterialApp.router y configuracion de tema global
        |-- core/
        |   |-- constants/          # Constantes de API y paleta de colores comercial
        |   |-- errors/             # Excepciones normalizadas (ApiException)
        |   |-- network/            # Cliente HTTP centralizado con Dio e interceptores
        |   |-- theme/              # Tema visual Material 3
        |   `-- utils/              # Formateadores monetarios (COP) y numericos
        |-- models/                 # Modelo Producto con fromJson, toJson y calculo de metricas
        |-- services/               # ProductoService con llamadas HTTP centralizadas
        |-- controllers/            # InventarioController (ChangeNotifier) y calculo de KPIs
        |-- routes/                 # Enrutamiento declarativo go_router
        |-- screens/
        |   |-- dashboard_screen.dart     # Dashboard con 3 KPIs obligatorios + alertas
        |   |-- productos_list_screen.dart # Catalogo con buscador, filtros y tarjetas
        |   |-- producto_detail_screen.dart # Informacion completa y acciones
        |   `-- producto_form_screen.dart   # Formulario unificado para Crear y Editar
        `-- widgets/                # Componentes modulares (MetricCard, ProductoCard, etc.)
```

---

## 3. Modelo de Datos y Entidad Producto

La tabla `productos` almacena los registros en `inventario.db` con los siguientes campos y tipos:

| Campo | Tipo | Restriccion / Validacion | Descripcion |
| :--- | :--- | :--- | :--- |
| `id` | Integer | Primary Key, Autoincrement | Identificador unico autogenerado |
| `nombre` | String(150) | Not Null, Min 1 char | Nombre comercial del producto |
| `codigo` | String(50) | Not Null, Unique, Min 1 char | Codigo de referencia unico (ej. `TEC-001`) |
| `descripcion` | Text | Nullable | Especificaciones tecnicas o notas |
| `precio` | Float | Not Null, Check `precio >= 0` | Precio unitario (validado en Pydantic y DB) |
| `cantidad` | Integer | Not Null, Check `cantidad >= 0` | Unidades en stock (entero no negativo) |
| `categoria` | String(100) | Not Null, Min 1 char | Categoria comercial |

---

## 4. Endpoints de la API REST

Documentacion interactiva disponible en: `http://localhost:8000/docs` (Swagger UI) y `http://localhost:8000/redoc`.

| Metodo | Endpoint | Codigo Exito | Codigos Error | Descripcion |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/` | 200 OK | - | Informacion general del servicio y endpoints |
| `GET` | `/api/productos` | 200 OK | 500 | Listar todos los productos del inventario |
| `GET` | `/api/productos/{id}` | 200 OK | 404, 500 | Obtener detalle de un producto por ID |
| `POST` | `/api/productos` | 201 Created | 400, 422, 500 | Registrar un nuevo producto con codigo unico |
| `PUT` | `/api/productos/{id}` | 200 OK | 400, 404, 422, 500 | Actualizar producto existente |
| `DELETE` | `/api/productos/{id}` | 200 OK | 404, 500 | Eliminar producto de la base de datos |

### Ejemplos de Peticiones y Respuestas

#### 1. Crear Producto (`POST /api/productos`)
**Solicitud:**
```json
POST /api/productos
Content-Type: application/json

{
  "nombre": "Teclado Mecanico Inalambrico",
  "codigo": "ACC-501",
  "descripcion": "Switches tactiles silenciosos, conexion Bluetooth y 2.4GHz",
  "precio": 420000.0,
  "cantidad": 15,
  "categoria": "Accesorios"
}
```

**Respuesta Exitosa (HTTP 201 Created):**
```json
{
  "id": 13,
  "nombre": "Teclado Mecanico Inalambrico",
  "codigo": "ACC-501",
  "descripcion": "Switches tactiles silenciosos, conexion Bluetooth y 2.4GHz",
  "precio": 420000.0,
  "cantidad": 15,
  "categoria": "Accesorios"
}
```

**Respuesta por Codigo Duplicado (HTTP 400 Bad Request):**
```json
{
  "detail": "Ya existe un producto con el codigo 'ACC-501'."
}
```

**Respuesta por Valores Negativos (HTTP 422 Unprocessable Content):**
```json
{
  "detail": "Error de validacion en los datos enviados.",
  "errores": [
    "body -> precio: Input should be greater than or equal to 0"
  ]
}
```

---

## 5. Guia de Ejecucion Paso a Paso

Para ejecutar la solucion, se deben abrir **dos terminales independientes**:

### Terminal 1: Iniciar el Backend (FastAPI + SQLite)

1. Navegar al directorio del backend:
   ```powershell
   cd C:\proyectos_moviles\inventario_parcial_flutter\backend
   ```
2. Activar el entorno virtual de Python:
   ```powershell
   .\venv\Scripts\Activate.ps1
   ```
3. Iniciar el servidor Uvicorn en `0.0.0.0:8000`:
   ```powershell
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```
   > Usar `--host 0.0.0.0` permite que tanto el emulador Android (`10.0.2.2:8000`) como dispositivos fisicos en LAN puedan conectarse.

4. Abrir en el navegador: `http://localhost:8000/docs` para ver Swagger UI interactivo.

### Terminal 2: Iniciar la Aplicacion Flutter

1. Navegar al directorio de Flutter:
   ```powershell
   cd C:\proyectos_moviles\inventario_parcial_flutter\frontend_flutter
   ```
2. Configuracion del archivo `.env` segun el dispositivo:
   - **Emulador Android (Android Studio):** `API_BASE_URL=http://10.0.2.2:8000/api`
   - **Windows Desktop / Chrome Web:** `API_BASE_URL=http://127.0.0.1:8000/api`
   - **Dispositivo Fisico:** `API_BASE_URL=http://<IP_LAN_PC>:8000/api` (ej. `http://10.10.88.221:8000/api`)
3. Ejecutar la aplicacion en el dispositivo deseado:
   ```powershell
   flutter run -d emulator-5554
   ```
   *(o `flutter run -d windows` / `flutter run -d chrome`)*

---

## 6. Pruebas Realizadas y Resultados

1. **Pruebas de Backend (`pytest test_api.py`):** 11/11 pruebas pasaron (100% exito).
2. **Analisis Estatico Flutter (`flutter analyze`):** 0 errores, 0 advertencias (`No issues found!`).
3. **Pruebas Unitarias de Flutter (`flutter test`):** Aprobadas (`All tests passed!`).
4. **Pruebas de Integracion HTTP en Vivo (`api_integration_test.dart`):** Comunicacion real con respuestas HTTP 200/201/delete comprobada.

---

## 7. Despliegue en la Nube (Opcional - 5%)

Para desplegar en servicios como **Render** o **Railway**:
1. Crear Web Service apuntando al directorio `backend/`.
2. Build Command: `pip install -r requirements.txt`
3. Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
4. Para persistir SQLite, adjuntar un **Persistent Disk** (ej. en `/data/inventario.db`).
5. En Flutter `.env`, configurar `API_BASE_URL=https://<su-app>.onrender.com/api` con HTTPS.
