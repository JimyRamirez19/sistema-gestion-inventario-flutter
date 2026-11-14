from typing import Optional
from pydantic import BaseModel, Field, field_validator, ConfigDict

class ProductoBase(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=150, description="Nombre del producto")
    codigo: str = Field(..., min_length=1, max_length=50, description="Código único del producto")
    descripcion: Optional[str] = Field(None, max_length=1000, description="Descripción opcional")
    precio: float = Field(..., ge=0.0, description="Precio unitario, debe ser >= 0")
    cantidad: int = Field(..., ge=0, description="Cantidad en stock, entero >= 0")
    categoria: str = Field(..., min_length=1, max_length=100, description="Categoría del producto")

    @field_validator("nombre", "codigo", "categoria", mode="before")
    @classmethod
    def strip_and_validate_not_empty(cls, value: str) -> str:
        if isinstance(value, str):
            cleaned = value.strip()
            if not cleaned:
                raise ValueError("Este campo no puede estar vacío ni contener solo espacios.")
            return cleaned
        return value

    @field_validator("descripcion", mode="before")
    @classmethod
    def clean_descripcion(cls, value: Optional[str]) -> Optional[str]:
        if isinstance(value, str):
            cleaned = value.strip()
            return cleaned if cleaned else None
        return value

class ProductoCreate(ProductoBase):
    pass

class ProductoUpdate(ProductoBase):
    pass

class ProductoResponse(ProductoBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

class MensajeResponse(BaseModel):
    message: str
    id: Optional[int] = None

# ==============================================================================
# ESQUEMAS PARA AUTENTICACIÓN Y USUARIOS
# ==============================================================================

class UserLogin(BaseModel):
    email: str = Field(..., min_length=3, max_length=150, description="Correo electrónico del usuario")
    password: str = Field(..., min_length=1, max_length=100, description="Contraseña en texto claro para validar")

    @field_validator("email", mode="before")
    @classmethod
    def validate_email_format(cls, value: str) -> str:
        if isinstance(value, str):
            cleaned = value.strip().lower()
            if not cleaned or "@" not in cleaned or "." not in cleaned.split("@")[-1]:
                raise ValueError("Debe ingresar una dirección de correo electrónico válida.")
            return cleaned
        return value

    @field_validator("password", mode="before")
    @classmethod
    def validate_password_not_empty(cls, value: str) -> str:
        if isinstance(value, str):
            cleaned = value.strip()
            if not cleaned:
                raise ValueError("La contraseña no puede estar vacía ni contener solo espacios.")
            return cleaned
        return value

class UserResponse(BaseModel):
    id: int
    nombre: str
    email: str
    is_active: bool = True

    model_config = ConfigDict(from_attributes=True)

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class TokenData(BaseModel):
    email: Optional[str] = None

