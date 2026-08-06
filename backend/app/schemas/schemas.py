from pydantic import BaseModel, EmailStr
from typing import Optional

class LoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UsuarioResponse(BaseModel):
    id: int
    email: str
    rol: str
    activo: bool

    class Config:
        from_attributes = True

from datetime import datetime

class SitioCreate(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    ubicacion: Optional[str] = None
    imagen_url: Optional[str] = None
    horario: Optional[str] = None

class SitioResponse(BaseModel):
    id: int
    nombre: str
    descripcion: Optional[str]
    ubicacion: Optional[str]
    imagen_url: Optional[str]
    activo: bool
    horario: Optional[str] = None

    class Config:
        from_attributes = True

class ZonaCreate(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    orden: Optional[int] = 0

class ZonaResponse(BaseModel):
    id: int
    sitio_id: int
    nombre: str
    descripcion: Optional[str]
    orden: int

    class Config:
        from_attributes = True

class ContenidoResponse(BaseModel):
    id: int
    zona_id: int
    tipo: str
    idioma: str
    url: Optional[str]
    texto: Optional[str]

    class Config:
        from_attributes = True

class QRResponse(BaseModel):
    id: int
    zona_id: int
    codigo: str
    url_destino: str
    creado_en: datetime

    class Config:
        from_attributes = True

class ZonaUpdate(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    orden: Optional[int] = None
    latitud: Optional[float] = None
    longitud: Optional[float] = None
    activa: Optional[bool] = None

class ContenidoCreate(BaseModel):
    tipo: str
    idioma: str = "es"
    url: Optional[str] = None
    texto: Optional[str] = None
    titulo: Optional[str] = None
    url_recurso: Optional[str] = None

class ContenidoUpdate(BaseModel):
    tipo: Optional[str] = None
    idioma: Optional[str] = None
    url: Optional[str] = None
    texto: Optional[str] = None
    titulo: Optional[str] = None
    url_recurso: Optional[str] = None

class RecorridoCreate(BaseModel):
    turista_id: int
    sitio_id: int

class RecorridoResponse(BaseModel):
    id: int
    turista_id: int
    sitio_id: int
    inicio: datetime
    fin: Optional[datetime] = None
    calificacion: Optional[float] = None
    comentario: Optional[str] = None

    class Config:
        from_attributes = True

class RecorridoFinish(BaseModel):
    calificacion: Optional[float] = None
    comentario: Optional[str] = None

class SitioUpdate(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    ubicacion: Optional[str] = None
    imagen_url: Optional[str] = None
    activo: Optional[bool] = None
    horario: Optional[str] = None