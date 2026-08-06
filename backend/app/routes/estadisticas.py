from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import SitioArqueologico, Zona, Usuario, VisitaZona, CodigoQR
from app.auth import verificar_token
from app.schemas.schemas import ResumenDashboard

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