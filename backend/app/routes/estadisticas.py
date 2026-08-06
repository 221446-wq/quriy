from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import SitioArqueologico, Zona, Usuario, VisitaZona, CodigoQR
from app.auth import verificar_token
from app.schemas.schemas import ResumenDashboard
from sqlalchemy import func
from datetime import datetime
from app.models.models import SitioArqueologico, Zona, Usuario, VisitaZona, CodigoQR, Recorrido
from app.schemas.schemas import (
    ResumenDashboard, SitioMasVisitado, EscaneosPorDia,
    EscaneosPorMes, IdiomaMasUsado, CalificacionPromedio
)
from typing import List

router = APIRouter(tags=["Estadísticas"])
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


@router.get("/estadisticas/resumen", response_model=ResumenDashboard)
def obtener_resumen_dashboard(
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    total_sitios = db.query(SitioArqueologico).filter(
        SitioArqueologico.activo == True
    ).count()
    total_zonas = db.query(Zona).count()
    total_usuarios = db.query(Usuario).filter(
        Usuario.activo == True
    ).count()
    total_visitas = db.query(VisitaZona).count()
    total_qrs = db.query(CodigoQR).count()

    return ResumenDashboard(
        total_sitios=total_sitios,
        total_zonas=total_zonas,
        total_usuarios=total_usuarios,
        total_visitas=total_visitas,
        total_qrs=total_qrs
    )

@router.get("/estadisticas/sitios-mas-visitados", response_model=List[SitioMasVisitado])
def obtener_sitios_mas_visitados(
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    from sqlalchemy import func
    resultados = (
        db.query(
            Zona.sitio_id,
            SitioArqueologico.nombre,
            func.count(VisitaZona.id).label("total")
        )
        .join(VisitaZona, VisitaZona.zona_id == Zona.id)
        .join(SitioArqueologico, SitioArqueologico.id == Zona.sitio_id)
        .group_by(Zona.sitio_id, SitioArqueologico.nombre)
        .order_by(func.count(VisitaZona.id).desc())
        .limit(10)
        .all()
    )
    return [
        SitioMasVisitado(
            sitio_id=r.sitio_id,
            nombre_sitio=r.nombre,
            total_visitas=r.total
        ) for r in resultados
    ]


@router.get("/estadisticas/escaneos-por-dia", response_model=List[EscaneosPorDia])
def obtener_escaneos_por_dia(
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    from sqlalchemy import func
    resultados = (
        db.query(
            func.date(VisitaZona.timestamp).label("fecha"),
            func.count(VisitaZona.id).label("total")
        )
        .group_by(func.date(VisitaZona.timestamp))
        .order_by(func.date(VisitaZona.timestamp).desc())
        .limit(30)
        .all()
    )
    return [
        EscaneosPorDia(fecha=str(r.fecha), total=r.total)
        for r in resultados
    ]


@router.get("/estadisticas/escaneos-por-mes", response_model=List[EscaneosPorMes])
def obtener_escaneos_por_mes(
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    from sqlalchemy import func
    resultados = (
        db.query(
            func.strftime("%Y-%m", VisitaZona.timestamp).label("mes"),
            func.count(VisitaZona.id).label("total")
        )
        .group_by(func.strftime("%Y-%m", VisitaZona.timestamp))
        .order_by(func.strftime("%Y-%m", VisitaZona.timestamp).desc())
        .all()
    )
    return [
        EscaneosPorMes(mes=r.mes, total=r.total)
        for r in resultados
    ]


@router.get("/estadisticas/idioma-mas-usado", response_model=List[IdiomaMasUsado])
def obtener_idioma_mas_usado(
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    from sqlalchemy import func
    resultados = (
        db.query(
            VisitaZona.idioma,
            func.count(VisitaZona.id).label("total")
        )
        .group_by(VisitaZona.idioma)
        .order_by(func.count(VisitaZona.id).desc())
        .all()
    )
    return [
        IdiomaMasUsado(idioma=r.idioma, total=r.total)
        for r in resultados
    ]


@router.get("/estadisticas/calificacion-promedio", response_model=List[CalificacionPromedio])
def obtener_calificacion_promedio(
    db: Session = Depends(get_db),
    admin: Usuario = Depends(verificar_admin)
):
    from sqlalchemy import func
    resultados = (
        db.query(
            VisitaZona.zona_id,
            Zona.nombre,
            func.avg(VisitaZona.calificacion).label("promedio"),
            func.count(VisitaZona.id).label("total")
        )
        .join(Zona, Zona.id == VisitaZona.zona_id)
        .filter(VisitaZona.calificacion != None)
        .group_by(VisitaZona.zona_id, Zona.nombre)
        .order_by(func.avg(VisitaZona.calificacion).desc())
        .all()
    )
    return [
        CalificacionPromedio(
            zona_id=r.zona_id,
            nombre_zona=r.nombre,
            promedio=round(r.promedio, 2),
            total_valoraciones=r.total
        ) for r in resultados
    ]