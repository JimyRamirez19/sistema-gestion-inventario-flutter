from sqlalchemy import Column, Integer, String, Text, Float, CheckConstraint
from database import Base

class Producto(Base):
    __tablename__ = "productos"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nombre = Column(String(150), nullable=False)
    codigo = Column(String(50), unique=True, index=True, nullable=False)
    descripcion = Column(Text, nullable=True)
    precio = Column(Float, nullable=False)
    cantidad = Column(Integer, nullable=False)
    categoria = Column(String(100), nullable=False)

    __table_args__ = (
        CheckConstraint("precio >= 0", name="check_precio_non_negative"),
        CheckConstraint("cantidad >= 0", name="check_cantidad_non_negative"),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "nombre": self.nombre,
            "codigo": self.codigo,
            "descripcion": self.descripcion,
            "precio": self.precio,
            "cantidad": self.cantidad,
            "categoria": self.categoria
        }
