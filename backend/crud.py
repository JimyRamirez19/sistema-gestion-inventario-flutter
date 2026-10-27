from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status
import models
import schemas

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
