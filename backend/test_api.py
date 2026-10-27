import os
import sys
import pytest
from fastapi.testclient import TestClient

# Ensure current dir is in path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from main import app
from database import Base, engine, SessionLocal
import models
from seed_data import seed_initial_products

client = TestClient(app)

def setup_module():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    seed_initial_products(db)
    db.close()

def test_1_listar_productos_iniciales():
    response = client.get("/api/productos")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 10
    print(f"\n[TEST 1 PASSED] Se listaron {len(data)} productos iniciales correctamente.")

def test_2_consultar_producto_existente():
    response = client.get("/api/productos/1")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == 1
    assert "nombre" in data
    assert "codigo" in data
    print(f"[TEST 2 PASSED] Producto ID 1 consultado exitosamente: {data['nombre']}")

def test_3_consultar_producto_inexistente():
    response = client.get("/api/productos/999999")
    assert response.status_code == 404
    data = response.json()
    assert "detail" in data
    print("[TEST 3 PASSED] Consulta de ID 999999 retornó 404 Not Found como se esperaba.")

def test_4_crear_producto_valido():
    nuevo_prod = {
        "nombre": "Micrófono Shure MV7 USB/XLR",
        "codigo": "AUD-TEST-99",
        "descripcion": "Micrófono dinámico profesional para podcast y streaming",
        "precio": 1150000.0,
        "cantidad": 5,
        "categoria": "Audio"
    }
    response = client.post("/api/productos", json=nuevo_prod)
    assert response.status_code == 201
    data = response.json()
    assert data["id"] is not None
    assert data["codigo"] == "AUD-TEST-99"
    assert data["precio"] == 1150000.0
    print(f"[TEST 4 PASSED] Producto creado exitosamente con ID {data['id']} (HTTP 201).")

def test_5_crear_producto_codigo_duplicado():
    duplicado = {
        "nombre": "Otro Micrófono Duplicado",
        "codigo": "AUD-TEST-99",
        "descripcion": "Debe fallar",
        "precio": 500000.0,
        "cantidad": 2,
        "categoria": "Audio"
    }
    response = client.post("/api/productos", json=duplicado)
    assert response.status_code == 400
    data = response.json()
    assert "detail" in data
    print("[TEST 5 PASSED] Intento de código duplicado rechazado con HTTP 400.")

def test_6_validaciones_precio_y_cantidad_invalidos():
    invalido_precio = {
        "nombre": "Producto Inválido",
        "codigo": "INV-001",
        "precio": -150.0,
        "cantidad": 5,
        "categoria": "Pruebas"
    }
    res1 = client.post("/api/productos", json=invalido_precio)
    assert res1.status_code == 422

    invalido_cant = {
        "nombre": "Producto Inválido",
        "codigo": "INV-002",
        "precio": 5000.0,
        "cantidad": -10,
        "categoria": "Pruebas"
    }
    res2 = client.post("/api/productos", json=invalido_cant)
    assert res2.status_code == 422
    print("[TEST 6 PASSED] Precios y cantidades negativas rechazadas con HTTP 422.")

def test_7_actualizar_producto_existente():
    # Fetch product created in test 4
    prods = client.get("/api/productos").json()
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
    response = client.put(f"/api/productos/{target['id']}", json=update_data)
    assert response.status_code == 200
    updated = response.json()
    assert updated["nombre"] == "Micrófono Shure MV7+ Actualizado"
    assert updated["precio"] == 1280000.0
    assert updated["cantidad"] == 9
    print(f"[TEST 7 PASSED] Producto ID {target['id']} actualizado exitosamente (HTTP 200).")

def test_8_actualizar_producto_inexistente():
    update_data = {
        "nombre": "Fantasma",
        "codigo": "GHOST-001",
        "precio": 10000.0,
        "cantidad": 1,
        "categoria": "General"
    }
    response = client.put("/api/productos/999999", json=update_data)
    assert response.status_code == 404
    print("[TEST 8 PASSED] Actualización de ID 999999 retornó 404 Not Found.")

def test_9_eliminar_producto_existente():
    prods = client.get("/api/productos").json()
    target = next((p for p in prods if p["codigo"] == "AUD-TEST-99"), None)
    assert target is not None

    response = client.delete(f"/api/productos/{target['id']}")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    print(f"[TEST 9 PASSED] Producto ID {target['id']} eliminado exitosamente (HTTP 200).")

def test_10_confirmar_producto_eliminado_no_aparece():
    prods = client.get("/api/productos").json()
    assert not any(p["codigo"] == "AUD-TEST-99" for p in prods)
    print("[TEST 10 PASSED] Confirmado: el producto eliminado ya no aparece en el listado.")

def test_11_persistencia_e_idempotencia_reinicio():
    # Simulate a second startup call to seed
    db = SessionLocal()
    inserted = seed_initial_products(db)
    db.close()
    assert inserted == 0, "No debe duplicar productos iniciales existentes"

    # Verify database file exists and is not empty
    db_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "inventario.db")
    assert os.path.exists(db_file)
    assert os.path.getsize(db_file) > 0
    print("[TEST 11 PASSED] Persistencia e idempotencia confirmadas en SQLite físico.")
