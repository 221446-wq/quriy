from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models.models import Contenido, Zona, Usuario
from app.auth import verificar_token
from app.schemas.schemas import ContenidoCreate, ContenidoUpdate, ContenidoResponse

router = APIRouter(tags=["Contenido Multimedia"])
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


@router.post("/zonas/{id}/contenido", response_model=ContenidoResponse, status_code=201)
def crear_contenido_zona(
    id: int,
    datos: ContenidoCreate,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    zona = db.query(Zona).filter(Zona.id == id).first()
    if not zona:
        raise HTTPException(status_code=404, detail="Zona no encontrada")
    contenido = Contenido(
        zona_id=id,
        tipo=datos.tipo,
        idioma=datos.idioma,
        url=datos.url,
        texto=datos.texto,
        titulo=datos.titulo,
        url_recurso=datos.url_recurso
    )
    db.add(contenido)
    db.commit()
    db.refresh(contenido)
    return contenido


@router.put("/contenido/{id}", response_model=ContenidoResponse)
def editar_contenido(
    id: int,
    datos: ContenidoUpdate,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    contenido = db.query(Contenido).filter(Contenido.id == id).first()
    if not contenido:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    if datos.tipo is not None:
        contenido.tipo = datos.tipo
    if datos.idioma is not None:
        contenido.idioma = datos.idioma
    if datos.url is not None:
        contenido.url = datos.url
    if datos.texto is not None:
        contenido.texto = datos.texto
    if datos.titulo is not None:
        contenido.titulo = datos.titulo
    if datos.url_recurso is not None:
        contenido.url_recurso = datos.url_recurso
    db.commit()
    db.refresh(contenido)
    return contenido


@router.delete("/contenido/{id}", status_code=204)
def eliminar_contenido(
    id: int,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    contenido = db.query(Contenido).filter(Contenido.id == id).first()
    if not contenido:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    db.delete(contenido)
    db.commit()
    return None

@router.get("/contenido/audios", response_model=List[ContenidoResponse])
def listar_biblioteca_audios(
    zona_id: int = None,
    idioma: str = None,
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    query = db.query(Contenido).filter(Contenido.tipo == "audio")

    if zona_id:
        query = query.filter(Contenido.zona_id == zona_id)
    if idioma:
        query = query.filter(Contenido.idioma == idioma)

    audios = query.order_by(Contenido.id.desc()).all()
    return audios