from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status
import models
import schemas
import auth

def get_productos(db: Session, skip: int = 0, limit: int = 1000) -> List[models.Producto]:
    return db.query(models.Producto).order_by(models.Producto.id.asc()).offset(skip).limit(limit).all()

def get_producto_by_id(db: Session, producto_id: int) -> Optional[models.Producto]:
    return db.query(models.Producto).filter(models.Producto.id == producto_id).first()

def get_producto_by_codigo(db: Session, codigo: str) -> Optional[models.Producto]:
    return db.query(models.Producto).filter(models.Producto.codigo == codigo.strip()).first()

def create_producto(db: Session, producto: schemas.ProductoCreate) -> models.Producto:
    # Check if duplicate code exists
    existing = get_producto_by_codigo(db, producto.codigo)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Ya existe un producto con el código '{producto.codigo}'."
        )

    db_producto = models.Producto(
        nombre=producto.nombre,
        codigo=producto.codigo,
        descripcion=producto.descripcion,
        precio=round(float(producto.precio), 2),
        cantidad=int(producto.cantidad),
        categoria=producto.categoria
    )
    try:
        db.add(db_producto)
        db.commit()
        db.refresh(db_producto)
        return db_producto
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error de integridad: el código '{producto.codigo}' ya se encuentra registrado."
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error inesperado al guardar el producto."
        )

def update_producto(db: Session, producto_id: int, producto_data: schemas.ProductoUpdate) -> models.Producto:
    db_producto = get_producto_by_id(db, producto_id)
    if not db_producto:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Producto con id {producto_id} no fue encontrado."
        )

    # Check if code is being changed to another existing product's code
    existing_code = get_producto_by_codigo(db, producto_data.codigo)
    if existing_code and existing_code.id != producto_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Ya existe otro producto con el código '{producto_data.codigo}'."
        )

    db_producto.nombre = producto_data.nombre
    db_producto.codigo = producto_data.codigo
    db_producto.descripcion = producto_data.descripcion
    db_producto.precio = round(float(producto_data.precio), 2)
    db_producto.cantidad = int(producto_data.cantidad)
    db_producto.categoria = producto_data.categoria

    try:
        db.commit()
        db.refresh(db_producto)
        return db_producto
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Error de integridad al actualizar el producto."
        )
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error inesperado al actualizar el producto."
        )

def delete_producto(db: Session, producto_id: int) -> bool:
    db_producto = get_producto_by_id(db, producto_id)
    if not db_producto:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Producto con id {producto_id} no fue encontrado para eliminar."
        )
    try:
        db.delete(db_producto)
        db.commit()
        return True
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error inesperado al eliminar el producto."
        )

# ==============================================================================
# OPERACIONES DE USUARIOS Y AUTENTICACIÓN
# ==============================================================================

def get_user_by_email(db: Session, email: str) -> Optional[models.Usuario]:
    """Busca un usuario en la base de datos por su correo electrónico (normalizado a minúsculas)."""
    cleaned_email = email.strip().lower()
    return db.query(models.Usuario).filter(models.Usuario.email == cleaned_email).first()

def get_user_by_id(db: Session, user_id: int) -> Optional[models.Usuario]:
    """Busca un usuario en la base de datos por su ID único."""
    return db.query(models.Usuario).filter(models.Usuario.id == user_id).first()

def create_user(
    db: Session,
    nombre: str,
    email: str,
    password: str,
    is_active: bool = True
) -> models.Usuario:
    """
    Crea un nuevo usuario en la base de datos aplicando hash seguro con bcrypt a la contraseña.
    Nunca almacena contraseñas en texto claro.
    """
    cleaned_email = email.strip().lower()
    existing = get_user_by_email(db, cleaned_email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El correo electrónico '{cleaned_email}' ya está registrado."
        )

    hashed = auth.hash_password(password)
    db_user = models.Usuario(
        nombre=nombre.strip(),
        email=cleaned_email,
        hashed_password=hashed,
        is_active=is_active
    )
    try:
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Error de integridad: el correo ya se encuentra en uso."
        )
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error inesperado al registrar el usuario."
        )

def authenticate_user(db: Session, email: str, password: str) -> Optional[models.Usuario]:
    """
    Autentica un usuario verificando su existencia y contrastando la contraseña
    en texto plano contra el hash almacenado mediante bcrypt.
    Retorna la instancia del modelo Usuario si es válido, o None en caso contrario.
    """
    user = get_user_by_email(db, email)
    if not user:
        return None
    if not auth.verify_password(password, user.hashed_password):
        return None
    return user

