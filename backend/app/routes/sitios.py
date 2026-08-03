from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List
import uuid
from app.database import get_db
from app.models.models import SitioArqueologico, Zona, Contenido, CodigoQR, Usuario
from app.auth import verificar_token
from app.schemas.schemas import (
    SitioCreate, SitioResponse,
    ZonaCreate, ZonaResponse, ZonaUpdate,
    ContenidoResponse, QRResponse
)

router = APIRouter(tags=["Sitios y Zonas"])
security = HTTPBearer()

def obtener_usuario_token(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    payload = verificar_token(credentials.credentials)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado"
        )
    usuario = db.query(Usuario).filter(
        Usuario.id == int(payload.get("sub"))
    ).first()
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no encontrado"
        )
    return usuario

def verificar_admin(usuario: Usuario = Depends(obtener_usuario_token)):
    if usuario.rol != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden realizar esta acción"
        )
    return usuario


@router.get("/sitios", response_model=List[SitioResponse])
def listar_sitios_arqueologicos(db: Session = Depends(get_db)):
    sitios = db.query(SitioArqueologico).filter(
        SitioArqueologico.activo == True
    ).all()
    return sitios


@router.post("/sitios", response_model=SitioResponse, status_code=201)
def crear_sitio_arqueologico(
    datos: SitioCreate,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    sitio = SitioArqueologico(
        nombre=datos.nombre,
        descripcion=datos.descripcion,
        ubicacion=datos.ubicacion,
        imagen_url=datos.imagen_url
    )
    db.add(sitio)
    db.commit()
    db.refresh(sitio)
    return sitio


@router.get("/sitios/{id}/zonas", response_model=List[ZonaResponse])
def listar_zonas_de_sitio(
    id: int,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(obtener_usuario_token)
):
    sitio = db.query(SitioArqueologico).filter(
        SitioArqueologico.id == id
    ).first()
    if not sitio:
        raise HTTPException(status_code=404, detail="Sitio no encontrado")
    zonas = db.query(Zona).filter(
        Zona.sitio_id == id
    ).order_by(Zona.orden).all()
    return zonas


@router.post("/sitios/{id}/zonas", response_model=ZonaResponse, status_code=201)
def crear_zona_en_sitio(
    id: int,
    datos: ZonaCreate,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    sitio = db.query(SitioArqueologico).filter(
        SitioArqueologico.id == id
    ).first()
    if not sitio:
        raise HTTPException(status_code=404, detail="Sitio no encontrado")
    zona = Zona(
        sitio_id=id,
        nombre=datos.nombre,
        descripcion=datos.descripcion,
        orden=datos.orden
    )
    db.add(zona)
    db.commit()
    db.refresh(zona)
    return zona


@router.get("/zonas/{id}/contenido", response_model=List[ContenidoResponse])
def listar_contenido_de_zona(
    id: int,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(obtener_usuario_token)
):
    zona = db.query(Zona).filter(Zona.id == id).first()
    if not zona:
        raise HTTPException(status_code=404, detail="Zona no encontrada")
    contenidos = db.query(Contenido).filter(
        Contenido.zona_id == id
    ).all()
    return contenidos


@router.post("/zonas/{id}/qr", response_model=QRResponse, status_code=201)
def generar_codigo_qr_zona(
    id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    zona = db.query(Zona).filter(Zona.id == id).first()
    if not zona:
        raise HTTPException(status_code=404, detail="Zona no encontrada")
    codigo_unico = str(uuid.uuid4())
    url_destino = f"https://quriy.app/zonas/{id}"
    qr = CodigoQR(
        zona_id=id,
        codigo=codigo_unico,
        url_destino=url_destino
    )
    db.add(qr)
    db.commit()
    db.refresh(qr)
    return qr

@router.put("/zonas/{id}", response_model=ZonaResponse)
def editar_zona(
    id: int,
    datos: ZonaUpdate,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    zona = db.query(Zona).filter(Zona.id == id).first()
    if not zona:
        raise HTTPException(status_code=404, detail="Zona no encontrada")

    if datos.nombre is not None:
        zona.nombre = datos.nombre
    if datos.descripcion is not None:
        zona.descripcion = datos.descripcion
    if datos.orden is not None:
        zona.orden = datos.orden
    if datos.latitud is not None:
        zona.latitud = datos.latitud
    if datos.longitud is not None:
        zona.longitud = datos.longitud
    if datos.activa is not None:
        zona.activa = datos.activa

    db.commit()
    db.refresh(zona)
    return zona


@router.delete("/zonas/{id}", status_code=204)
def eliminar_zona(
    id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    zona = db.query(Zona).filter(Zona.id == id).first()
    if not zona:
        raise HTTPException(status_code=404, detail="Zona no encontrada")

    db.delete(zona)
    db.commit()
    return None