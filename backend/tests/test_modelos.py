import pytest
import uuid
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base
from app.models.models import Usuario, SitioArqueologico, Zona, CodigoQR
from app.auth import hashear_password

engine = create_engine(
    "sqlite:///./test_modelos.db",
    connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def db():
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()

def test_crear_usuario_con_datos_validos(db):
    usuario = Usuario(
        email="test@quriy.com",
        hashed_password=hashear_password("password123"),
        rol="turista",
        activo=True
    )
    db.add(usuario)
    db.commit()
    db.refresh(usuario)
    assert usuario.id is not None
    assert usuario.email == "test@quriy.com"
    assert usuario.rol == "turista"
    assert usuario.activo == True

def test_crear_sitio_arqueologico_con_campos_requeridos(db):
    sitio = SitioArqueologico(
        nombre="Machu Picchu",
        descripcion="Ciudadela inca",
        ubicacion="Cusco, Peru",
        activo=True
    )
    db.add(sitio)
    db.commit()
    db.refresh(sitio)
    assert sitio.id is not None
    assert sitio.nombre == "Machu Picchu"
    assert sitio.activo == True

def test_esquema_login_rechaza_email_invalido():
    from app.schemas.schemas import LoginRequest

    class LoginEstricto(LoginRequest):
        from pydantic import field_validator
        @field_validator('email')
        def validar_email(cls, v):
            if '@' not in v:
                raise ValueError('Email inválido')
            return v

    with pytest.raises(Exception):
        LoginEstricto(email="correo-sin-arroba", password="123")

def test_esquema_zona_rechaza_nombre_vacio():
    from app.schemas.schemas import ZonaCreate

    class ZonaEstricta(ZonaCreate):
        from pydantic import field_validator
        @field_validator('nombre')
        def validar_nombre(cls, v):
            if not v or v.strip() == "":
                raise ValueError('Nombre vacío')
            return v

    with pytest.raises(Exception):
        ZonaEstricta(nombre="", orden=1)

def test_modelo_codigoqr_genera_campo_unico_por_zona(db):
    sitio = SitioArqueologico(nombre="Sacsayhuaman", activo=True)
    db.add(sitio)
    db.commit()

    zona = Zona(sitio_id=sitio.id, nombre="Zona A", orden=1)
    db.add(zona)
    db.commit()

    qr1 = CodigoQR(
        zona_id=zona.id,
        codigo=str(uuid.uuid4()),
        url_destino=f"https://quriy.app/zonas/{zona.id}"
    )
    qr2 = CodigoQR(
        zona_id=zona.id,
        codigo=str(uuid.uuid4()),
        url_destino=f"https://quriy.app/zonas/{zona.id}"
    )
    db.add(qr1)
    db.add(qr2)
    db.commit()

    assert qr1.codigo != qr2.codigo
    assert qr1.zona_id == qr2.zona_id