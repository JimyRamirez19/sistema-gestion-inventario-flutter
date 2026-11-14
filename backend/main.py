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
import auth
from seed_data import seed_initial_products, seed_initial_user

# Lifespan: initialize database and idempotent seed data
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure tables exist
    Base.metadata.create_all(bind=engine)
    # Seed initial products and default administrator
    db = next(get_db())
    try:
        count = seed_initial_products(db)
        admin = seed_initial_user(db)
        admin_email = admin.email if admin else "N/A"
        print(f"[STARTUP] Base de datos lista. {count} productos procesados. Usuario administrador verificado: {admin_email}.")
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
            "autenticacion_login": "POST /api/auth/login",
            "autenticacion_me": "GET /api/auth/me",
            "listar_productos": "GET /api/productos",
            "detalle_producto": "GET /api/productos/{id}",
            "crear_producto": "POST /api/productos",
            "actualizar_producto": "PUT /api/productos/{id}",
            "eliminar_producto": "DELETE /api/productos/{id}"
        }
    }

# ==============================================================================
# ENDPOINTS DE AUTENTICACIÓN JWT
# ==============================================================================

# A. POST /api/auth/login - Iniciar sesión y obtener JWT
@app.post(
    "/api/auth/login",
    response_model=schemas.TokenResponse,
    status_code=status.HTTP_200_OK,
    tags=["Autenticación"],
    summary="Iniciar sesión y obtener JWT",
    description="Valida las credenciales del usuario y genera un token JWT firmado."
)
def login(credentials: schemas.UserLogin, db: Session = Depends(get_db)):
    user = crud.authenticate_user(db, email=credentials.email, password=credentials.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales incorrectas: correo o contraseña inválidos.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="La cuenta del usuario se encuentra inactiva.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Generación del token JWT con el email en el claim 'sub'
    access_token = auth.create_access_token(
        data={"sub": user.email, "user_id": user.id, "nombre": user.nombre}
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }

# B. GET /api/auth/me - Obtener información del usuario autenticado
@app.get(
    "/api/auth/me",
    response_model=schemas.UserResponse,
    status_code=status.HTTP_200_OK,
    tags=["Autenticación"],
    summary="Consultar información de la sesión actual",
    description="Retorna los datos del usuario autenticado a partir del JWT enviado en el header Authorization: Bearer <token>."
)
def get_current_user_info(current_user: models.Usuario = Depends(auth.get_current_user)):
    return current_user


# 1. GET /api/productos - Listar todos los productos (PROTEGIDO)
@app.get(
    "/api/productos",
    response_model=List[schemas.ProductoResponse],
    tags=["Productos"],
    summary="Listar todos los productos",
    description="Retorna la lista completa de productos registrados en el inventario. Requiere token JWT en header Authorization."
)
def listar_productos(
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(auth.get_current_user)
):
    return crud.get_productos(db)

# 2. GET /api/productos/{id} - Consultar detalle de un producto (PROTEGIDO)
@app.get(
    "/api/productos/{id}",
    response_model=schemas.ProductoResponse,
    tags=["Productos"],
    summary="Consultar detalle de un producto",
    description="Retorna la información completa de un producto específico mediante su ID. Requiere token JWT en header Authorization."
)
def obtener_producto(
    id: int,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(auth.get_current_user)
):
    producto = crud.get_producto_by_id(db, producto_id=id)
    if not producto:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Producto con id {id} no fue encontrado."
        )
    return producto

# 3. POST /api/productos - Registrar un producto (PROTEGIDO)
@app.post(
    "/api/productos",
    response_model=schemas.ProductoResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Productos"],
    summary="Registrar un nuevo producto",
    description="Crea un nuevo producto en el inventario validando unicidad de código y valores no negativos. Requiere token JWT."
)
def crear_producto(
    producto: schemas.ProductoCreate,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(auth.get_current_user)
):
    return crud.create_producto(db, producto)

# 4. PUT /api/productos/{id} - Actualizar un producto existente (PROTEGIDO)
@app.put(
    "/api/productos/{id}",
    response_model=schemas.ProductoResponse,
    status_code=status.HTTP_200_OK,
    tags=["Productos"],
    summary="Actualizar un producto",
    description="Actualiza la totalidad de atributos de un producto existente. Requiere token JWT en header Authorization."
)
def actualizar_producto(
    id: int,
    producto: schemas.ProductoUpdate,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(auth.get_current_user)
):
    return crud.update_producto(db, producto_id=id, producto_data=producto)

# 5. DELETE /api/productos/{id} - Eliminar un producto (PROTEGIDO)
@app.delete(
    "/api/productos/{id}",
    response_model=schemas.MensajeResponse,
    status_code=status.HTTP_200_OK,
    tags=["Productos"],
    summary="Eliminar un producto",
    description="Elimina permanentemente un producto de la base de datos por su ID. Requiere token JWT en header Authorization."
)
def eliminar_producto(
    id: int,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(auth.get_current_user)
):
    crud.delete_producto(db, producto_id=id)
    return {"message": f"Producto con id {id} eliminado exitosamente.", "id": id}

if __name__ == "__main__":
    import uvicorn
    # Listening on 0.0.0.0:8000 allows connections from Android emulator (10.0.2.2) and LAN devices
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
