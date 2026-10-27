import os
from contextlib import asynccontextmanager
from typing import List
from fastapi import FastAPI, Depends, HTTPException, status, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.orm import Session

from database import engine, Base, get_db
import models
import schemas
import crud
from seed_data import seed_initial_products

# Lifespan: initialize database and idempotent seed data
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure tables exist
    Base.metadata.create_all(bind=engine)
    # Seed initial products
    db = next(get_db())
    try:
        count = seed_initial_products(db)
        print(f"[STARTUP] Base de datos lista. {count} productos iniciales insertados (idempotente).")
    finally:
        db.close()
    yield
    print("[SHUTDOWN] Servidor detenido ordenadamente.")

app = FastAPI(
    title="API de Gestión de Inventario",
    description="API RESTful para administración de productos de inventario. Proyecto Electiva Profesional I.",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS configuration for Flutter (web, mobile emulator 10.0.2.2, LAN devices, desktop)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Custom validation error handler for friendly JSON responses
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = []
    for err in exc.errors():
        loc = " -> ".join([str(l) for l in err.get("loc", [])])
        msg = err.get("msg", "Dato inválido")
        errors.append(f"{loc}: {msg}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "detail": "Error de validación en los datos enviados.",
            "errores": errors
        }
    )

# Root endpoint
@app.get("/", tags=["General"])
def read_root():
    return {
        "sistema": "Sistema de Gestión de Inventario",
        "asignatura": "Electiva Profesional I - Desarrollo de Aplicaciones Móviles",
        "evaluacion": "Segundo Parcial Práctico",
        "version": "1.0.0",
        "estado": "Activo y persistente (SQLite)",
        "documentacion": "/docs",
        "endpoints_principales": {
            "listar_productos": "GET /api/productos",
            "detalle_producto": "GET /api/productos/{id}",
            "crear_producto": "POST /api/productos",
            "actualizar_producto": "PUT /api/productos/{id}",
            "eliminar_producto": "DELETE /api/productos/{id}"
        }
    }

# 1. GET /api/productos - Listar todos los productos
@app.get(
    "/api/productos",
    response_model=List[schemas.ProductoResponse],
    tags=["Productos"],
    summary="Listar todos los productos",
    description="Retorna la lista completa de productos registrados en el inventario."
)
def listar_productos(db: Session = Depends(get_db)):
    return crud.get_productos(db)

# 2. GET /api/productos/{id} - Consultar detalle de un producto
@app.get(
    "/api/productos/{id}",
    response_model=schemas.ProductoResponse,
    tags=["Productos"],
    summary="Consultar detalle de un producto",
    description="Retorna la información completa de un producto específico mediante su ID."
)
def obtener_producto(id: int, db: Session = Depends(get_db)):
    producto = crud.get_producto_by_id(db, producto_id=id)
    if not producto:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Producto con id {id} no fue encontrado."
        )
    return producto

# 3. POST /api/productos - Registrar un producto
@app.post(
    "/api/productos",
    response_model=schemas.ProductoResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Productos"],
    summary="Registrar un nuevo producto",
    description="Crea un nuevo producto en el inventario validando unicidad de código y valores no negativos."
)
def crear_producto(producto: schemas.ProductoCreate, db: Session = Depends(get_db)):
    return crud.create_producto(db, producto)

# 4. PUT /api/productos/{id} - Actualizar un producto existente
@app.put(
    "/api/productos/{id}",
    response_model=schemas.ProductoResponse,
    status_code=status.HTTP_200_OK,
    tags=["Productos"],
    summary="Actualizar un producto",
    description="Actualiza la totalidad de atributos de un producto existente."
)
def actualizar_producto(id: int, producto: schemas.ProductoUpdate, db: Session = Depends(get_db)):
    return crud.update_producto(db, producto_id=id, producto_data=producto)

# 5. DELETE /api/productos/{id} - Eliminar un producto
@app.delete(
    "/api/productos/{id}",
    response_model=schemas.MensajeResponse,
    status_code=status.HTTP_200_OK,
    tags=["Productos"],
    summary="Eliminar un producto",
    description="Elimina permanentemente un producto de la base de datos por su ID."
)
def eliminar_producto(id: int, db: Session = Depends(get_db)):
    crud.delete_producto(db, producto_id=id)
    return {"message": f"Producto con id {id} eliminado exitosamente.", "id": id}

if __name__ == "__main__":
    import uvicorn
    # Listening on 0.0.0.0:8000 allows connections from Android emulator (10.0.2.2) and LAN devices
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
