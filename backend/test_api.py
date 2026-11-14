import os
import sys
from datetime import timedelta
import pytest
from fastapi.testclient import TestClient

# Asegurar que el directorio actual esté en sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from main import app
from database import Base, engine, SessionLocal
import models
import auth
from seed_data import seed_initial_products, seed_initial_user

client = TestClient(app)

def setup_module():
    """Inicializa la base de datos y siembra productos y usuario administrador."""
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    seed_initial_products(db)
    seed_initial_user(db)
    db.close()

def get_auth_headers() -> dict:
    """Función auxiliar para obtener cabeceras con JWT válido mediante login real."""
    admin_email = os.getenv("SEED_ADMIN_EMAIL", "admin@inventario.com")
    admin_pw = os.getenv("SEED_ADMIN_PASSWORD")
    response = client.post("/api/auth/login", json={"email": admin_email, "password": admin_pw})
    assert response.status_code == 200, f"Error al autenticar para pruebas: {response.text}"
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

# ==============================================================================
# PRUEBAS ORIGINALES DEL PARCIAL 2 (ADAPTADAS CON AUTENTICACIÓN JWT)
# ==============================================================================

def test_1_listar_productos_iniciales():
    headers = get_auth_headers()
    response = client.get("/api/productos", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 10
    print(f"\n[TEST 1 PASSED] Se listaron {len(data)} productos iniciales correctamente con JWT.")

def test_2_consultar_producto_existente():
    headers = get_auth_headers()
    response = client.get("/api/productos/1", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == 1
    assert "nombre" in data
    assert "codigo" in data
    print(f"[TEST 2 PASSED] Producto ID 1 consultado exitosamente con JWT: {data['nombre']}")

def test_3_consultar_producto_inexistente():
    headers = get_auth_headers()
    response = client.get("/api/productos/999999", headers=headers)
    assert response.status_code == 404
    data = response.json()
    assert "detail" in data
    print("[TEST 3 PASSED] Consulta de ID 999999 retornó 404 Not Found como se esperaba.")

def test_4_crear_producto_valido():
    headers = get_auth_headers()
    nuevo_prod = {
        "nombre": "Micrófono Shure MV7 USB/XLR",
        "codigo": "AUD-TEST-99",
        "descripcion": "Micrófono dinámico profesional para podcast y streaming",
        "precio": 1150000.0,
        "cantidad": 5,
        "categoria": "Audio"
    }
    response = client.post("/api/productos", json=nuevo_prod, headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert data["id"] is not None
    assert data["codigo"] == "AUD-TEST-99"
    assert data["precio"] == 1150000.0
    print(f"[TEST 4 PASSED] Producto creado exitosamente con ID {data['id']} (HTTP 201) usando JWT.")

def test_5_crear_producto_codigo_duplicado():
    headers = get_auth_headers()
    duplicado = {
        "nombre": "Otro Micrófono Duplicado",
        "codigo": "AUD-TEST-99",
        "descripcion": "Debe fallar",
        "precio": 500000.0,
        "cantidad": 2,
        "categoria": "Audio"
    }
    response = client.post("/api/productos", json=duplicado, headers=headers)
    assert response.status_code == 400
    data = response.json()
    assert "detail" in data
    print("[TEST 5 PASSED] Intento de código duplicado rechazado con HTTP 400.")

def test_6_validaciones_precio_y_cantidad_invalidos():
    headers = get_auth_headers()
    invalido_precio = {
        "nombre": "Producto Inválido",
        "codigo": "INV-001",
        "precio": -150.0,
        "cantidad": 5,
        "categoria": "Pruebas"
    }
    res1 = client.post("/api/productos", json=invalido_precio, headers=headers)
    assert res1.status_code == 422

    invalido_cant = {
        "nombre": "Producto Inválido",
        "codigo": "INV-002",
        "precio": 5000.0,
        "cantidad": -10,
        "categoria": "Pruebas"
    }
    res2 = client.post("/api/productos", json=invalido_cant, headers=headers)
    assert res2.status_code == 422
    print("[TEST 6 PASSED] Precios y cantidades negativas rechazadas con HTTP 422.")

def test_7_actualizar_producto_existente():
    headers = get_auth_headers()
    # Fetch product created in test 4
    prods = client.get("/api/productos", headers=headers).json()
    target = next((p for p in prods if p["codigo"] == "AUD-TEST-99"), None)
    assert target is not None

    update_data = {
        "nombre": "Micrófono Shure MV7+ Actualizado",
        "codigo": "AUD-TEST-99",
        "descripcion": "Versión Plus con DSP mejorado y luz LED RGB",
        "precio": 1280000.0,
        "cantidad": 9,
        "categoria": "Audio Profesional"
    }
    response = client.put(f"/api/productos/{target['id']}", json=update_data, headers=headers)
    assert response.status_code == 200
    updated = response.json()
    assert updated["nombre"] == "Micrófono Shure MV7+ Actualizado"
    assert updated["precio"] == 1280000.0
    assert updated["cantidad"] == 9
    print(f"[TEST 7 PASSED] Producto ID {target['id']} actualizado exitosamente (HTTP 200).")

def test_8_actualizar_producto_inexistente():
    headers = get_auth_headers()
    update_data = {
        "nombre": "Fantasma",
        "codigo": "GHOST-001",
        "precio": 10000.0,
        "cantidad": 1,
        "categoria": "General"
    }
    response = client.put("/api/productos/999999", json=update_data, headers=headers)
    assert response.status_code == 404
    print("[TEST 8 PASSED] Actualización de ID 999999 retornó 404 Not Found.")

def test_9_eliminar_producto_existente():
    headers = get_auth_headers()
    prods = client.get("/api/productos", headers=headers).json()
    target = next((p for p in prods if p["codigo"] == "AUD-TEST-99"), None)
    assert target is not None

    response = client.delete(f"/api/productos/{target['id']}", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    print(f"[TEST 9 PASSED] Producto ID {target['id']} eliminado exitosamente (HTTP 200).")

def test_10_confirmar_producto_eliminado_no_aparece():
    headers = get_auth_headers()
    prods = client.get("/api/productos", headers=headers).json()
    assert not any(p["codigo"] == "AUD-TEST-99" for p in prods)
    print("[TEST 10 PASSED] Confirmado: el producto eliminado ya no aparece en el listado.")

def test_11_persistencia_e_idempotencia_reinicio():
    # Simulate a second startup call to seed
    db = SessionLocal()
    inserted = seed_initial_products(db)
    inserted_user = seed_initial_user(db)
    db.close()
    assert inserted == 0, "No debe duplicar productos iniciales existentes"
    assert inserted_user is not None, "Usuario administrador debe mantenerse existente"

    # Verify database file exists and is not empty
    db_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "inventario.db")
    assert os.path.exists(db_file)
    assert os.path.getsize(db_file) > 0
    print("[TEST 11 PASSED] Persistencia e idempotencia confirmadas en SQLite físico.")

# ==============================================================================
# NUEVAS PRUEBAS DE AUTENTICACIÓN Y PROTECCIÓN JWT (TALLER JWT)
# ==============================================================================

def test_12_acceso_sin_token_rechazado_401():
    """Verifica que los 5 endpoints CRUD rechacen peticiones sin token con HTTP 401."""
    # 1. GET /api/productos
    res_list = client.get("/api/productos")
    assert res_list.status_code == 401
    assert "no se proporcionó el token" in res_list.json()["detail"].lower()

    # 2. GET /api/productos/{id}
    res_get = client.get("/api/productos/1")
    assert res_get.status_code == 401

    # 3. POST /api/productos
    res_post = client.post("/api/productos", json={"nombre": "X", "codigo": "X-1", "precio": 10, "cantidad": 1, "categoria": "C"})
    assert res_post.status_code == 401

    # 4. PUT /api/productos/{id}
    res_put = client.put("/api/productos/1", json={"nombre": "X", "codigo": "X-1", "precio": 10, "cantidad": 1, "categoria": "C"})
    assert res_put.status_code == 401

    # 5. DELETE /api/productos/{id}
    res_del = client.delete("/api/productos/1")
    assert res_del.status_code == 401

    print("[TEST 12 PASSED] Los 5 endpoints CRUD rechazaron peticiones sin token con HTTP 401.")

def test_13_acceso_con_token_invalido_rechazado_401():
    """Verifica que enviar un token JWT malformado o alterado sea rechazado con HTTP 401."""
    invalid_headers = {"Authorization": "Bearer token_falso_invalido_12345"}
    
    res1 = client.get("/api/productos", headers=invalid_headers)
    assert res1.status_code == 401
    assert "inválido" in res1.json()["detail"].lower()

    res2 = client.get("/api/auth/me", headers=invalid_headers)
    assert res2.status_code == 401

    print("[TEST 13 PASSED] Peticiones con token inválido rechazadas con HTTP 401.")

def test_14_acceso_con_token_expirado_rechazado_401():
    """Verifica que un token expirado sea rechazado con HTTP 401."""
    expired_token = auth.create_access_token(
        data={"sub": "admin@inventario.com"},
        expires_delta=timedelta(seconds=-30)
    )
    expired_headers = {"Authorization": f"Bearer {expired_token}"}

    response = client.get("/api/productos", headers=expired_headers)
    assert response.status_code == 401
    assert "expirado" in response.json()["detail"].lower()
    print("[TEST 14 PASSED] Token expirado rechazado con HTTP 401.")

def test_15_flujo_login_y_usuario_autenticado():
    """Verifica el flujo completo de login y consulta de sesión en /api/auth/me."""
    admin_email = os.getenv("SEED_ADMIN_EMAIL", "admin@inventario.com")
    admin_pw = os.getenv("SEED_ADMIN_PASSWORD")

    # 1. Login exitoso
    res_login = client.post("/api/auth/login", json={"email": admin_email, "password": admin_pw})
    assert res_login.status_code == 200
    token_data = res_login.json()
    assert "access_token" in token_data
    assert token_data["token_type"] == "bearer"
    assert token_data["user"]["email"] == admin_email
    assert "hashed_password" not in token_data["user"]

    # 2. Login con contraseña errónea
    res_wrong = client.post("/api/auth/login", json={"email": admin_email, "password": "ClaveIncorrecta*"})
    assert res_wrong.status_code == 401

    # 3. Consulta /api/auth/me con el token obtenido
    headers = {"Authorization": f"Bearer {token_data['access_token']}"}
    res_me = client.get("/api/auth/me", headers=headers)
    assert res_me.status_code == 200
    user_info = res_me.json()
    assert user_info["email"] == admin_email
    assert user_info["is_active"] is True
    assert "hashed_password" not in user_info

    print("[TEST 15 PASSED] Flujo de autenticación login y /api/auth/me verificado con éxito.")
