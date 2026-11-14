import os
from datetime import datetime, timezone, timedelta
from typing import Optional
from dotenv import load_dotenv
import bcrypt
import jwt
from jwt.exceptions import PyJWTError, ExpiredSignatureError
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from database import get_db
import models
import schemas

# ==============================================================================
# CARGA Y VALIDACIÓN DE CONFIGURACIÓN DE SEGURIDAD
# ==============================================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_FILE = os.path.join(BASE_DIR, ".env")
load_dotenv(ENV_FILE)

SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    raise RuntimeError(
        "CRÍTICO: SECRET_KEY no está configurada en las variables de entorno. "
        "Verifique la existencia de backend/.env."
    )

ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

# Esquema HTTPBearer de FastAPI para el encabezado 'Authorization: Bearer <token>'
# auto_error=False nos permite controlar la respuesta 401 explícita requerida por el taller
security = HTTPBearer(auto_error=False)

# ==============================================================================
# FUNCIONES DE HASHING Y VERIFICACIÓN DE CONTRASEÑAS (BCRYPT)
# ==============================================================================

def hash_password(password: str) -> str:
    """
    Genera un hash seguro utilizando bcrypt con una sal aleatoria (salt).
    Garantiza que ninguna contraseña se almacene en texto plano.
    """
    password_bytes = password.encode("utf-8")
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password_bytes, salt)
    return hashed.decode("utf-8")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Compara una contraseña en texto claro contra el hash bcrypt almacenado.
    Retorna True si coincide, False en caso contrario.
    """
    try:
        plain_bytes = plain_password.encode("utf-8")
        hashed_bytes = hashed_password.encode("utf-8")
        return bcrypt.checkpw(plain_bytes, hashed_bytes)
    except Exception:
        return False

# ==============================================================================
# FUNCIONES DE CREACIÓN Y DECODIFICACIÓN DE JSON WEB TOKENS (PYJWT)
# ==============================================================================

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Genera y firma digitalmente un JWT con algoritmo HS256 y fecha de expiración.
    """
    to_encode = data.copy()
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({
        "exp": expire,
        "iat": now
    })

    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str) -> dict:
    """
    Decodifica y valida la firma y vigencia de un JWT.
    Lanza HTTP 401 si el token expiró o su firma es inválida.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El token de autenticación ha expirado. Por favor, inicie sesión nuevamente.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticación inválido o alterado.",
            headers={"WWW-Authenticate": "Bearer"},
        )

# ==============================================================================
# DEPENDENCIA FASTAPI: OBTENER USUARIO AUTENTICADO (PROTECCIÓN DE SERVICIOS)
# ==============================================================================

def get_current_user(
    auth: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_db)
) -> models.Usuario:
    """
    Dependencia de FastAPI inyectable mediante Depends(get_current_user).
    
    1. Verifica la presencia de la cabecera 'Authorization: Bearer <token>'.
    2. Decodifica y valida el token JWT.
    3. Recupera el usuario desde la base de datos mediante su email ('sub').
    4. Comprueba que el usuario exista y esté activo.
    
    Cualquier fallo retorna HTTP 401 Unauthorized.
    """
    if not auth or not auth.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No se proporcionó el token de autenticación en la cabecera 'Authorization'.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = auth.credentials
    payload = decode_access_token(token)

    email: Optional[str] = payload.get("sub")
    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El token de autenticación no contiene un identificador de usuario válido.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = db.query(models.Usuario).filter(models.Usuario.email == email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El usuario asociado a este token no existe en el sistema.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El usuario asociado a este token se encuentra inactivo.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user

