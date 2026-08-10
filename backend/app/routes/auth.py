import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import Usuario, Turista
from app.auth import (
    verificar_password,
    hashear_password,
    crear_token,
    verificar_token,
    verificar_id_token_google,
)
from app.schemas.schemas import LoginRequest, GoogleLoginRequest, TokenResponse, UsuarioResponse

router = APIRouter(prefix="/auth", tags=["Autenticación"])
security = HTTPBearer()

@router.post("/login", response_model=TokenResponse)
def autenticar_usuario(datos: LoginRequest, db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(Usuario.email == datos.email).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales incorrectas"
        )

    if not verificar_password(datos.password, usuario.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales incorrectas"
        )

    if not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario inactivo"
        )

    token = crear_token({"sub": str(usuario.id), "rol": usuario.rol})
    return {"access_token": token, "token_type": "bearer"}


@router.post("/google", response_model=TokenResponse)
def autenticar_con_google(datos: GoogleLoginRequest, db: Session = Depends(get_db)):
    payload = verificar_id_token_google(datos.id_token)

    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de Google inválido o expirado"
        )

    email = payload.get("email")
    if not email or not payload.get("email_verified"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El correo de Google no está verificado"
        )

    google_id = payload["sub"]
    usuario = db.query(Usuario).filter(Usuario.email == email).first()

    if usuario is None:
        # Primer login con Google: se crea la cuenta automáticamente.
        # La contraseña queda con un valor aleatorio e inutilizable, ya
        # que este usuario solo podrá ingresar mediante Google.
        usuario = Usuario(
            email=email,
            hashed_password=hashear_password(uuid.uuid4().hex),
            rol="turista",
            activo=True,
            proveedor="google",
            google_id=google_id,
        )
        db.add(usuario)
        db.commit()
        db.refresh(usuario)

        db.add(Turista(
            usuario_id=usuario.id,
            nombre=payload.get("name") or email.split("@")[0],
        ))
        db.commit()
    elif not usuario.google_id:
        # Cuenta local existente con el mismo email: se vincula con Google
        # sin tocar su contraseña, para que ambos métodos sigan sirviendo.
        usuario.google_id = google_id
        db.commit()

    if not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario inactivo"
        )

    token = crear_token({"sub": str(usuario.id), "rol": usuario.rol})
    return {"access_token": token, "token_type": "bearer"}


@router.post("/logout")
def cerrar_sesion():
    return {"mensaje": "Sesión cerrada correctamente"}


@router.get("/me", response_model=UsuarioResponse)
def obtener_usuario_actual(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    token = credentials.credentials
    payload = verificar_token(token)

    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado"
        )

    usuario_id = int(payload.get("sub"))
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no encontrado"
        )

    return usuario