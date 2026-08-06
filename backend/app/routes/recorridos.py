from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from datetime import datetime
from app.database import get_db
from app.models.models import Recorrido, Turista, SitioArqueologico, Usuario
from app.auth import verificar_token
from app.schemas.schemas import RecorridoCreate, RecorridoResponse, RecorridoFinish

router = APIRouter(tags=["Recorridos"])
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


@router.post("/recorridos", response_model=RecorridoResponse, status_code=201)
def iniciar_recorrido(
    datos: RecorridoCreate,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(obtener_usuario_token)
):
    turista = db.query(Turista).filter(
        Turista.id == datos.turista_id
    ).first()
    if not turista:
        raise HTTPException(status_code=404, detail="Turista no encontrado")

    sitio = db.query(SitioArqueologico).filter(
        SitioArqueologico.id == datos.sitio_id
    ).first()
    if not sitio:
        raise HTTPException(status_code=404, detail="Sitio no encontrado")

    recorrido = Recorrido(
        turista_id=datos.turista_id,
        sitio_id=datos.sitio_id,
        inicio=datetime.utcnow()
    )
    db.add(recorrido)
    db.commit()
    db.refresh(recorrido)
    return recorrido


@router.put("/recorridos/{id}", response_model=RecorridoResponse)
def finalizar_recorrido(
    id: int,
    datos: RecorridoFinish,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(obtener_usuario_token)
):
    recorrido = db.query(Recorrido).filter(Recorrido.id == id).first()
    if not recorrido:
        raise HTTPException(status_code=404, detail="Recorrido no encontrado")
    if recorrido.fin:
        raise HTTPException(status_code=400, detail="El recorrido ya fue finalizado")

    recorrido.fin = datetime.utcnow()
    if datos.calificacion is not None:
        recorrido.calificacion = datos.calificacion
    if datos.comentario is not None:
        recorrido.comentario = datos.comentario

    db.commit()
    db.refresh(recorrido)
    return recorrido