import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.database import Base, get_db
from app.models.models import Usuario, Turista as TuristaPerfil, Administrador
from app.auth import hashear_password

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_quriy.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(autouse=True)
def setup_database():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()

    admin = Usuario(
        email="admin@quriy.com",
        hashed_password=hashear_password("admin123"),
        rol="admin",
        activo=True
    )
    turista = Usuario(
        email="turista@quriy.com",
        hashed_password=hashear_password("turista123"),
        rol="turista",
        activo=True
    )
    db.add(admin)
    db.add(turista)
    db.commit()

    # Perfiles asociados a cada usuario (necesarios para flujos de
    # integración que registran visitas o vinculan al administrador)
    admin_perfil = Administrador(
        usuario_id=admin.id,
        nombre="Administrador Quriy Test",
        institucion="Municipalidad de Cusco"
    )
    turista_perfil = TuristaPerfil(
        usuario_id=turista.id,
        nombre="Turista Demo Test",
        idioma_preferido="es"
    )
    db.add(admin_perfil)
    db.add(turista_perfil)
    db.commit()
    db.close()

    yield

    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def client():
    return TestClient(app)

@pytest.fixture
def token_admin(client):
    response = client.post("/auth/login", json={
        "email": "admin@quriy.com",
        "password": "admin123"
    })
    return response.json()["access_token"]

@pytest.fixture
def token_turista(client):
    response = client.post("/auth/login", json={
        "email": "turista@quriy.com",
        "password": "turista123"
    })
    return response.json()["access_token"]

@pytest.fixture
def turista_id():
    """ID del perfil Turista (tabla turistas) creado en setup_database,
    necesario para endpoints que registran visitas (VisitaZonaCreate.turista_id)."""
    db = TestingSessionLocal()
    perfil = db.query(TuristaPerfil).first()
    id_perfil = perfil.id
    db.close()
    return id_perfil