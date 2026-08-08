from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models.models import VisitaZona, Zona, Turista, Usuario, SitioArqueologico
from app.auth import verificar_token
from app.schemas.schemas import VisitaZonaCreate, VisitaZonaResponse, ValoracionResponse

router = APIRouter(tags=["Visitas y Valoraciones"])
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


@router.post("/visitas-zona", response_model=VisitaZonaResponse, status_code=201)
def registrar_visita_zona(
    datos: VisitaZonaCreate,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(obtener_usuario_token)
):
    turista = db.query(Turista).filter(Turista.id == datos.turista_id).first()
    if not turista:
        raise HTTPException(status_code=404, detail="Turista no encontrado")

    zona = db.query(Zona).filter(Zona.id == datos.zona_id).first()
    if not zona:
        raise HTTPException(status_code=404, detail="Zona no encontrada")

    visita = VisitaZona(
        turista_id=datos.turista_id,
        zona_id=datos.zona_id,
        idioma=datos.idioma,
        metodo_acceso=datos.metodo_acceso,
        calificacion=datos.calificacion,
        comentario=datos.comentario
    )
    db.add(visita)
    db.commit()
    db.refresh(visita)
    return visita


@router.get("/valoraciones", response_model=List[ValoracionResponse])
def listar_valoraciones(
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    visitas = db.query(VisitaZona).filter(
        VisitaZona.calificacion != None
    ).all()

    resultado = []
    for visita in visitas:
        zona = db.query(Zona).filter(Zona.id == visita.zona_id).first()
        sitio = db.query(SitioArqueologico).filter(
            SitioArqueologico.id == zona.sitio_id
        ).first() if zona else None

        resultado.append(ValoracionResponse(
            id=visita.id,
            turista_id=visita.turista_id,
            zona_id=visita.zona_id,
            timestamp=visita.timestamp,
            calificacion=visita.calificacion,
            comentario=visita.comentario,
            nombre_zona=zona.nombre if zona else None,
            nombre_sitio=sitio.nombre if sitio else None
        ))
    return resultado